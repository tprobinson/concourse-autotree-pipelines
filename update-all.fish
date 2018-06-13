#!/usr/bin/env fish
set common_configs -l common-vars.yml -l credentials.yml
set concourse_url https://concourse-prod.example.com

set team_color 567ACB
set job_color 00867C
set fail_color A00
set disabled_color DAA800
set good_color 00A524

source fly_team_authentications.fish
if [ ! $status ]
  echo "Could not find fly_team_authentications.fish!"
  exit 1
end

for teamPath in teams/*
  set team (basename $teamPath)
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

  for jobPath in $teamPath/*
    set jobName (basename $jobPath)
    set_color $job_color
    echo -n "$jobName: "
    set_color normal
    if [ -f $jobPath/disabled ]
      set_color $disabled_color
      echo "disabled"
      set_color normal
      continue
    end

    # If we have a variants folder, use those to determine the jobs.
    # Otherwise just do one.
    if [ -d $jobPath/variants ]
      echo
      for jobVariantPath in $jobPath/variants/*
        set variantName (basename $jobVariantPath | cut -d'.' -f1)

        fly -t $team set-pipeline -n -p $variantName -c $jobPath/$jobName.yml -l $jobVariantPath $common_configs >/dev/null

        if [ ! $status ]
          set_color $fail_color
          echo "  $variantName"
          set_color normal
          exit 1
        else
          set_color $good_color
          echo "  $variantName"
          set_color normal
        end
      end
    else
      fly -t $team set-pipeline -n -p $jobName -c $jobPath/$jobName.yml $common_configs >/dev/null

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
set_color $good_color
echo 'Done!'
set_color normal
