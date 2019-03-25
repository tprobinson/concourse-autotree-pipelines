#!/bin/bash
set -e -u
common_configs='-l common-vars.yml -l credentials.yml'

team_color="$(tput setaf 5)"
job_color="$(tput setaf 6)"
fail_color="$(tput setaf 1)"
disabled_color="$(tput setaf 3)"
good_color="$(tput setaf 2)"
normal="$(tput sgr0)"

source fly_team_authentications.bash
if [ ! $? ]; then
  echo "Could not find fly_team_authentications.bash!"
  exit 1
fi

for teamPath in teams/*; do
  team="$(basename $teamPath)"
  echo -n "${team_color}Logging in to team $team: ${normal}"

  fly -t $team login \
    -n $team -c $concourse_url \
    -u "$(eval echo \$"$team"_username)" \
    -p "$(eval echo \$"$team"_password)" \
    >/dev/null

  if [ ! $? ]; then
    echo "${fail_color}failed!${normal}"
    exit 1
  else
    echo "${good_color}done${normal}"
  fi

  for jobPath in $teamPath/*; do
    jobName="$(basename $jobPath)"
    echo -n "${job_color}$jobName: ${normal}"
    if [ -f $jobPath/disabled ]; then
      echo "${disabled_color}disabled${normal}"
      continue
    fi

    # If we have a variants folder, use those to determine the jobs.
    # Otherwise just do one.
    if [ -d $jobPath/variants ]; then
      echo
      for jobVariantPath in $jobPath/variants/*; do
        variantName="$(basename $jobVariantPath | cut -d'.' -f1)"

        fly -t $team set-pipeline -n -p $variantName -c $jobPath/$jobName.yml -l $jobVariantPath $common_configs >/dev/null

        if [ ! $? ]; then
          echo "${fail_color}  $variantName${normal}"
          exit 1
        else
          echo "${good_color}  $variantName${normal}"
        fi
      done
    else
      fly -t $team set-pipeline -n -p $jobName -c $jobPath/$jobName.yml $common_configs >/dev/null

      if [ ! $? ]; then
        echo "${fail_color}failed!${normal}"
        exit 1
      else
        echo "${good_color}done${normal}"
      fi
    fi
  done
done
echo "${good_color}Done!${normal}"
