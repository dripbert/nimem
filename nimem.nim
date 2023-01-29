import std/[strutils, times, algorithm]
import os

var notes_file: string = get_env("HOME") & "/.nimem_notes"
const msg_length = 47


proc is_numeric(str: string): bool =
    var n: bool = true
    for c in str:
        if not contains($c, Digits):
            n = false
    return n

proc str_norm(str: string, msg_length: int): string =
    var new_str: string = str
    if len(str) > msg_length:
      new_str = str[0..msg_length-4] & "..."
    elif len(str) < msg_length:
      let repeat_by: int = (msg_length - len(str))
      new_str = str & repeat(" ", repeat_by)
    return new_str

proc pr_col(pr: int): string =
    assert pr <= 2 and pr >= 0, "priority must be between 0 and 2"
    if   pr == 2:
        return "\e[32;1m" 
    elif pr == 1:
        return "\e[33;1m" 
    else:
        return "\e[31;1m" 

proc get_notes(file: string): seq =
    let notes = read_file(file).split('\n')
    return notes

proc print_notes(file: string): void =
    let notes: seq = get_notes(file)

    var i: int = 0
    # priority|message|date
    let table: string = "nr. pr.|   " & str_norm("message", msg_length) & "       Date"
    echo table
    for note in notes:
        if note == "": continue
        var note_s  = note.split('|')
        var priority: string = pr_col(parse_int(note_s[0])) & note_s[0] & "\e[0m"
        var message: string  = "\e[1m"  & note_s[1].str_norm(msg_length) & "\e[0m"
        var date: string     = "\e[34m" & note_s[2] & "\e[0m"
        let nr: string = str_norm($i, 1)
        let line: string = nr & " > " & priority & "  | " & "[ \"" & message & "\" ]" & " | " & date 
        i += 1
        echo line

proc write_note(file: string): void =
    let f = open(file, fm_append)
    defer: f.close

    stdout.write("note [new note]> ")
    var note: string = readline(stdin) 
    if note == "": note = "new note"

    stdout.write("priority (0-2)[0]> ")
    var pr: string = readline(stdin)
    if pr == "": pr = "0"
    if not is_numeric(pr):
        echo "invalid number `" & pr & "`"
        return
    if parse_int(pr) < 0 or parse_int(pr) > 2:
        echo "priority must be between 0 and 2"
        return

    let date_now: string = split($now(), "T")[0]
    stdout.write("date [" & date_now & "]> ")
    var date: string = readline(stdin)
    if date == "": date = date_now

    # priority|message|date
    write_line(f, pr & "|" & note & "|" & date)

proc overwrite_notes(file: string, notes: seq): void =
    var f = open(file, fm_write)
    write(f, "")
    close(f)

    f = open(file, fm_append)
    defer: f.close
    for note in notes:
        write_line(f, note)

proc clear_blank_lines(file: string): void =
    let notes:   seq = get_notes(file)
    var no_spcs: seq[string]

    for note in notes:
        if note != "":
            add(no_spcs, note)
    overwrite_notes(file, no_spcs)

proc delete_note(file: string): void =
    print_notes(notes_file)
    stdout.write("delete (nr.)> ")
    let note = readline(stdin)
    if not is_numeric(note):
        echo "invalid number `" & note & "`"
        return

    var notes: seq = get_notes(file)
    delete(notes, parse_int(note))

    overwrite_notes(file, notes)

proc sort_by_pr(file: string): void =
    var notes: seq = get_notes(file)
    sort(notes)

    overwrite_notes(file, notes)

proc swap_notes(file: string): void =
    var notes = get_notes(file)

    stdout.write("first> ")
    let s1: string = readline(stdin)
    if not is_numeric(s1):
        echo "invalid number `" & s1 & "`"
        return

    stdout.write("second> ")
    let s2: string = readline(stdin)

    if s1 == "" or s2 == "":
        echo "please put in a number"
        return
    if not is_numeric(s2):
        echo "invalid number `" & s2 & "`"
        return

    let i1: int = parse_int(s1)
    let i2: int = parse_int(s2)

    let n1: string = notes[i1] 
    let n2: string = notes[i2] 
    delete(notes, i2)
    insert(notes, n1, i2)
    delete(notes, i1)
    insert(notes, n2, i1)

    overwrite_notes(file, notes)

proc print_help(): void =
    echo "Options:"
    echo " >list   - list notes"
    echo " >add    - add note"
    echo " >del    - delete note"
    echo " >sort   - sort notes by priority"
    echo " >swap   - mannualy move notes"
    echo " >quit   - quit"

if not file_exists(notes_file):
    write_file(notes_file, "")

clear_blank_lines(notes_file)
var input: string
while true:
    stdout.write("nimone> ")
    input = readline(stdin)

    case input:
      of "add":
          write_note(notes_file)
      of "del":
          delete_note(notes_file)
      of "sort":
          sort_by_pr(notes_file)
      of "list":
          print_notes(notes_file)
      of "swap":
          swap_notes(notes_file)
      of "help":
          print_help()
      of "quit":
          quit(0)
      else:
          echo "Unrecognized command `" & input & "`.\nType help for help."
