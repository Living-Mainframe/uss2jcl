#!/usr/bin/env sh

# create temporary history file
OUTFILE="/tmp/uss2jcl.$(date +%H%M%S)"
touch "$OUTFILE"
trap 'rm "$OUTFILE"' EXIT
if [ ! -f "$OUTFILE" ]
then
    printf "failed to create %s" "$OUTFILE"
    exit 1
fi

# shell: $SHELL or /bin/sh as a fallback
NEW_SHELL="/bin/sh"
if [ -n "$SHELL" ]
then
    NEW_SHELL="$SHELL"
fi
if [ "$(basename "$NEW_SHELL")" != "sh" ]
then
    printf "\nWarning: shell is %s, consider using sh instead.\n" \
    "$NEW_SHELL"
fi

# editor: $EDITOR or vi as a fallback
EDIT="vi"
if [ -n "$EDITOR" ]
then
    EDIT=$EDITOR
fi

# spawn new shell
printf "\nStarting recording, output is: %s\n" "$OUTFILE"
printf "Spawning new shells will break this program.\n"
printf "Type exit to stop the recording.\n\n"
env \
    HISTFILE="$OUTFILE" \
    HISTFILESIZE=1000 \
    HISTCONTROL="" \
    HISTIGNORE="" \
    "$NEW_SHELL"

# exit if output is empty
if [ ! -s "$OUTFILE" ] 
then
    exit 0
fi

# check maximum line length
ALLOWED_LENGTH=70
MAX_LENGTH="$(awk '{print length}' "$OUTFILE"| sort | tail -1)"
if [ "$MAX_LENGTH" -gt "$ALLOWED_LENGTH" ]
then
    printf "\nWarning: maximum line length exceeds %s.\n" \
    "$ALLOWED_LENGTH"
fi

# edit recording
printf "\nEdit the recording in %s [y/N]?" "$EDIT"
read -r E
if [ "$E" = "y" ]
then
    $EDIT "$OUTFILE"
fi

# save recording as a shell script
printf "\nSave as a shell script?\n"
printf "Enter a filename, leave empty to skip: "
read -r SAVEFILE
if [ -n "$SAVEFILE" ]
then
    cp "$OUTFILE" "$SAVEFILE"
    printf "1i\n#!/usr/bin/env %s\n.\nwq\n" \
    "$(basename "$NEW_SHELL")" | ex "$SAVEFILE"
fi

# save recording as a jcl file
printf "\nSave as a jcl file?\n"
printf "Enter a filename, leave empty to skip: "
read -r SAVEFILE
if [ -n "$SAVEFILE" ]
then
    cp "$OUTFILE" "$SAVEFILE"
    ex "$SAVEFILE" << EOF
%s/^/ /
%s/$/;/
1i
//USS2JCL JOB (ACCT),MSGCLASS=H,NOTIFY=&SYSUID.
//STEP1     EXEC PGM=BPXBATCH
//STDOUT    DD   SYSOUT=*
//STDERR    DD   SYSOUT=*
//STDPARM   DD   *
SH
.
wq
EOF
    printf "/*\n" >> "$SAVEFILE"
fi
