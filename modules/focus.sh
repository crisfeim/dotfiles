focus() {
    osascript -e 'display notification "Se ha iniciado la sesión de trabajo" with title "Sesión de trabajo"'
    osascript -e 'tell application "System Events" to set quitList to name of every application process whose background only is false and name is not "iTerm2" and name is not "Focus"' -e 'repeat with appName in quitList' -e 'tell application appName to quit' -e 'end repeat'
    open -a "IINA" /Users/cristian/Music/Music/Media.localized/Music/Focus/Youtube/Chimenea.m4a
}

chimenea() { iina ~/Music/Music/Media.localized/Music/Focus/Youtube/Chimenea.m4a }
anima() { iina ~/"Music/Music/Media.localized/Music/Marco Frisina/Unknown Album/Anima Christi.mp3" }
gregorian() { iina ~/"Music/Music/Media.localized/Music/Benedictine Monks/Unknown Album/Gregorian Chants of the Benedictine Monks.mp3" }
