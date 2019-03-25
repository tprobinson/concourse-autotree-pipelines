#!/usr/bin/env fish
source fly_team_authentications.fish
if [ ! $status ]
  echo "Could not find fly_team_authentications!"
  exit 1
end
set common_configs -l common-vars.yml -l credentials.yml

set team_color 567ACB
set job_color 00867C
set variant_color 0A518D
set warn_color DABB01
set fail_color A00
set disabled_color DAA800
set good_color 00A524

set dry_run 0
if [ count $argv -gt 0 ]; and [ $argv[1] = '-n' ]
  set dry_run 1
end

for teamPath in teams/*
  set -l team (basename $teamPath)
  set_color $team_color
  echo -n "Logging in to team $team: "
  set_color normal

  fly -t $team login \
    -n $team -c $concourse_url \
    -u (eval echo \$"$team"_username) \
    -p (eval echo \$"$team"_password) \
    >/dev/null

  if [ ! $status ]
    set_color $fail_color
    echo 'failed!'
    set_color normal
    exit 1
  else
    set_color $good_color
    echo 'done'
    set_color normal
  end

  # Get a list of all pipelines on the server
  set -l pipelinesOnServer (fly -t $team ps --json | jq -r '.[].name' | string split ' ')

  # Get a list of all pipelines we have
  set -l pipelinesOnDisk

  for jobPath in $teamPath/*
    set -l jobName (basename $jobPath)
    set -l jobFullPath "$jobPath/$jobName.yml"

    if [ -f $jobPath/disabled ]
      set pipelinesOnDisk $pipelinesOnDisk "$jobName|disabled"
      continue
    end

    # If we have a variants folder, use those to determine the jobs.
    # Otherwise just do one.
    if [ -d $jobPath/variants ]
      for jobVariantPath in $jobPath/variants/*
        set -l variantName (basename $jobVariantPath | cut -d'.' -f1)
        set pipelinesOnDisk $pipelinesOnDisk "$jobName|variant|$jobFullPath|$variantName|$jobVariantPath"
        continue
      end
    else
      set pipelinesOnDisk $pipelinesOnDisk "$jobName|pipeline|$jobFullPath"
      continue
    end
  end

  # Delete any pipelines that do not exist on disk.
  for i in $pipelinesOnServer
    set -l found 0
    for j in $pipelinesOnDisk
      set -l jobData (echo $j | string split '|')

      # Name is different if variant or not
      set -l jobName $jobData[1]
      if [ $jobData[2] = 'variant' ]
        set jobName $jobData[4]
      end

      if [ $i = $jobName ]
        set found 1
        break
      end
    end

    if [ $found = 0 ]
      set_color $warn_color
      echo -n "Deleting $i... "
      set_color normal

      if [ $dry_run = 1 ]
        echo 'would have been deleted'
      else

        # Redirected because Fly says things during non-interactive for some reason
        fly -t $team destroy-pipeline -n -p $i >/dev/null

        if [ ! $status ]
          set_color $fail_color
          echo 'failed!'
          set_color normal
          exit 1
        else
          set_color $good_color
          echo 'done'
          set_color normal
        end

      end
    end
  end


  # Set all other pipelines.
  for i in $pipelinesOnDisk
    # Get variables from the packed string
    set -l jobData (echo $i | string split '|')

    switch $jobData[2]
    case pipeline
      # Handle typical pipelines
      set_color $job_color
      echo -n $jobData[1]": "
      set_color normal

      if [ $dry_run = 1 ]
        echo 'would have been set'
      else

        fly -t $team set-pipeline -n -p $jobData[1] -c $jobData[3] $common_configs >/dev/null

        if [ ! $status ]
          set_color $fail_color
          echo 'failed!'
          set_color normal
          exit 1
        else
          set_color $good_color
          echo 'done'
          set_color normal
        end

      end

    case variant
      # Handle variant pipelines
      set_color $variant_color
      echo -n $jobData[4]": "
      set_color normal

      if [ $dry_run = 1 ]
        echo 'would have been set'
      else

        fly -t $team set-pipeline -n -p $jobData[4] -c $jobData[3] -l $jobData[5] $common_configs >/dev/null

        if [ ! $status ]
          set_color $fail_color
          echo 'failed!'
          set_color normal
          exit 1
        else
          set_color $good_color
          echo 'done'
          set_color normal
        end

      end

    case disabled
      # Handle disabled pipelines
      set_color $job_color
      echo -n $jobData[1]": "
      set_color $disabled_color
      echo "disabled"
      set_color normal
    end
  end
end
set_color $good_color
echo 'Done!'
set_color normal
