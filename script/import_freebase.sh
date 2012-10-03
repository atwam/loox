#!/bin/sh

load_file() {
  local INPUT_FILE=$1
  [ -z "${INPUT_FILE}" ] && echo "ERROR: File not specified" && return 1

  echo "Loading file ${INPUT_FILE}"

  COLLECTION=`echo ${INPUT_FILE} | cut -d. -f-2`

  FIELDS=`head -1 ${INPUT_FILE} | sed -e "s/	/,/g;s/ /_/g"`
  #echo "mongoimport -d freebase -c ${COLLECTION} -type tsv --headerline -f $FIELDS --drop ${INPUT_FILE}"
  echo "mongoimport -d freebase -c entities -type tsv --headerline -f $FIELDS ${INPUT_FILE}"
  #time mongoimport -d freebase -c ${COLLECTION} -type tsv --headerline -f $FIELDS --drop ${INPUT_FILE}
  time mongoimport -d freebase -c entities -type tsv --headerline -f $FIELDS ${INPUT_FILE}
  return 0
}

download() {
  local FILENAME=$1
  local LOCALFILENAME=$2

  if [ -e $LOCALFILENAME ];
  then
    echo "Not downloading ${FILENAME} since ${LOCALFILENAME} exists"
  else
    echo "Downloading ${FILENAME} to ${LOCALFILENAME}"
    wget "http://download.freebase.com/datadumps/latest/browse/${FILENAME}.tsv" -O ${LOCALFILENAME}
  fi

  return 0
}

process_dir() {
  echo "Processing" `pwd`
  for FILE in `ls *.tsv`
  do
    load_file ${FILE}
  done

  return 0
}

main() {
  list = {
  tv/tv_director
  tv/tv_actor
  tv/tv_series_episode
  tv/tv_guest_personal_appearance
  tv/tv_guest_role
  tv/tv_genre
  tv/tv_character
  tv/tv_episode_segment
  tv/tv_series_season
  music/artist
  music/live_album
  music/soundtrack
  music/album
  music/single
  music/genre
  music/album_release_type
  music/musical_group
  music/track
  music/release_component
  music/track_contribution
  music/release
  music/composer
  music/songwriter
  music/group_member
  music/concert
  music/group_membership
  film/writer
  film/actor
  film/film_collection
  film/film_awards_ceremony
  film/content_rating
  film/film_critic
  film/producer
  film/film_series
  film/film_crewmember
  film/film
  film/music_contributor
  film/film_location
  film/film_featured_song
  film/person_or_entity_appearing_in_film
  film/film_genre
  film/film_subject
  film/personal_film_appearance_type
  film/film_character
  film/personal_film_appearance
  film/director
}

  for FILENAME in ${list}
  do
    LOCALFILENAME=`echo ${FILENAME}|sed -e "s/\//./g"`
    download(${FILENAME},${LOCALFILENAME})
  done

  process_dir

}

main $*
exit 0

