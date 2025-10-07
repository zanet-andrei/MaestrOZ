def transpose(note, semitones):
    notes = ["c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"]
    if len(note) == 1:
        octave = 4
    elif len(note) < 1:
        return 0
    elif note[1] == "#":
            octave = note[2]
    else:
        octave = note[1]
    
    new_note_semitones = ((notes.index(note)+1)*octave) + semitones
    new_note = notes[(new_note_semitones -1 ) % 12]
    new_octave = (new_note_semitones // 12)
    if semitones != 0:
        new_octave += 1
    return str(new_note)+str(new_octave)
    
print(transpose("b", -4))
print(transpose("b", 4))