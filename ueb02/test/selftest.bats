#!/usr/bin/env bats
#Autoren : Mak Masic, Luka Pervan
BATS_TEST_TIMEOUT=10

setup_file() {
    # sicherstellen, dass $DUT gesetzt ist!!
    if [ -z ${DUT+x} ]; then
        echo 'DUT not set'
        exit 1
    fi
    bats_require_minimum_version 1.11.0
}

setup() {
    # zusätzliche asserts laden
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-file/load'
}

teardown() {
    # nach jedem Testfall aufräumen
    rm -f ./test/data/out/*.out
    # Ausgabe bei Fehlschlag
    echo "Aufruf: $BATS_RUN_COMMAND"
    echo "Exit-Code: $status"
}

@test "01: Dezimalwerte werden korrekt sortiert" {
    # Skript mit Dezimal Testdaten füttern und Ausgabe in Out Datei schreiben
    run --separate-stderr "$DUT" ./test/data/out/01DezimalTest.out \
        < ./test/data/in/01DezimalTest.in

    # sollte fehlerfrei laufen
    assert_success

    # auf STDOUT erwarten wir das Feld 2 der kleinsten Zahl: 'three'
    assert_output 'three'

    # keine Fehler auf STDERR
    [ -z "$stderr" ]

    # komplette Out Datei mit der Referenz vergleichen
    diff ./test/data/out/01DezimalTest.out ./test/data/exp/01DezimalTest.exp
}

@test "02: Negative Werte → kleinstes (negativ) auswählen" {
    # Wir starten das Skript und leiten die Eingabe aus der Datei zu,
    # tee schreibt das Ergebnis in ./test/data/out/02NegativeTest.out
    run --separate-stderr "$DUT" ./test/data/out/02NegativeTest.out \
        < ./test/data/in/02NegativeTest.in

    # Das Skript soll ohne Fehler enden (Exit Code 0)
    assert_success

    # Auf STDOUT erwarten wir 'minus1'  das ist der kleinste (negativste) Wert
    assert_output 'minus1'

    # STDERR muss leer bleiben, es dürfen keine Fehlermeldungen auftreten
    [ -z "$stderr" ]

    # Zum Schluss vergleichen wir die komplette Ausgabedatei mit unserer
    # Referenzdatei, damit Format und Reihenfolge genau passen
    diff ./test/data/out/02NegativeTest.out ./test/data/exp/02NegativeTest.exp
}

@test "03: Sehr große Zahlen (BigInt) korrekt behandelt" {
    # Skript mit unserem großenZahlen Input aufrufen,
    # tee schreibt die Ausgabe in die Out Datei
    run --separate-stderr "$DUT" ./test/data/out/03LargeNumbersTest.out \
        < ./test/data/in/03LargeNumbersTest.in

    # sollte ohne Fehler durchlaufen
    assert_success

    # wir erwarten, dass das kleinste BigInt Element
    # (Feld 2) ausgegeben wird
    assert_output 'smallest'

    # keine Fehlermeldungen
    [ -z "$stderr" ]

    # und die komplette Datei muss genau mit der Referenz übereinstimmen
    diff ./test/data/out/03LargeNumbersTest.out ./test/data/exp/03LargeNumbersTest.exp
}

@test "04: Fehlendes drittes Feld wird als 0 behandelt" {
    # Wir starten das Skript und leiten unsere Input Datei als STDIN rein.
    # tee schreibt alles in die Out Datei, während --separate-stderr ERR in $stderr hält.
    run --separate-stderr "$DUT" ./test/data/out/04MissingThirdFieldTest.out \
        < ./test/data/in/04MissingThirdFieldTest.in

    # Das Skript soll ohne Fehler durchlaufen (Exit Code 0).
    assert_success

    # Da das dritte Feld fehlt, behandeln wir es wie 0. Nach Sortierung
    # ist die letzte Zeile das Item mit Feld2 "onlytwofields".
    assert_output 'onlytwofields'

    # Es darf nichts auf STDERR gelandet sein.
    [ -z "$stderr" ]

    # Am Ende vergleichen wir die erzeugte Datei mit unserer Erwartungs Datei.
    # diff gibt 0 zurück, wenn sie exakt übereinstimmen.
    diff ./test/data/out/04MissingThirdFieldTest.out ./test/data/exp/04MissingThirdFieldTest.exp
}

@test "05: Duplikate mit identischen Keys → nur erster Eintrag bleibt" {
    # Wir führen das Skript aus und speichern die Ausgabe in einer Datei,
    # während Fehler in $stderr landen.
    run --separate-stderr "$DUT" ./test/data/out/05DuplicateKeysTest.out \
        < ./test/data/in/05DuplicateKeysTest.in

    # Das Skript soll ohne Fehler enden (Exit Code 0).
    assert_success

    # Auf STDOUT erwarten wir 'first'  denn nur der erste von
    # zwei doppelten Einträgen bleibt erhalten.
    assert_output 'first'

    # Es darf keine Nachricht auf STDERR erscheinen.
    [ -z "$stderr" ]

    # Abschließend vergleichen wir die komplette Out Datei
    # mit unserer Referenz in test/data/exp.
    diff ./test/data/out/05DuplicateKeysTest.out ./test/data/exp/05DuplicateKeysTest.exp
}

@test "06: Substring '<Failed' in Feld 2 führt zum Filtern" {
    # Starte das Skript und sammle Ausgabe in einer Datei, Fehler separat
    run --separate-stderr "$DUT" ./test/data/out/06FailedSubstringTest.out \
        < ./test/data/in/06FailedSubstringTest.in

    # Das Skript soll ohne Fehler enden
    assert_success

    # Auf STDOUT erwarten wir 'ok'  nur die Zeile ohne "<Failed>" bleibt
    assert_output 'ok'

    # Es darf nichts auf STDERR gelandet sein
    [ -z "$stderr" ]

    # Vergleiche die komplette generierte Datei mit unserer Referenz
    diff ./test/data/out/06FailedSubstringTest.out ./test/data/exp/06FailedSubstringTest.exp
}

@test "07: Gemischte Schreibweise '<FaIlEd>' wird entfernt" {
    # Wir starten das Skript und leiten die Test Eingabe ein,
    # Fehlerausgaben landen in $stderr, die Ausgabe in ./test/data/out/…
    run --separate-stderr "$DUT" ./test/data/out/07MixedCaseFailedTest.out \
        < ./test/data/in/07MixedCaseFailedTest.in

    # Das Skript soll erfolgreich (Exit Code 0) enden
    assert_success

    # Auf STDOUT muss das verbliebene Feld 2 stehen: 'survive'
    assert_output 'survive'

    # STDERR muss leer bleiben  keine Fehlermeldungen
    [ -z "$stderr" ]

    # Abschließend vergleichen wir die komplette Out Datei
    # mit unserer Referenz in test/data/exp
    diff ./test/data/out/07MixedCaseFailedTest.out ./test/data/exp/07MixedCaseFailedTest.exp
}

@test "08: Einzelzeile → gibt direkt Feld 2 aus" {
    # Wir rufen das Skript auf und leiten den Inhalt der Input Datei als STDIN rein.
    # Gleichzeitig schreibt tee in die Out Datei, die wir später vergleichen.
    run --separate-stderr "$DUT" ./test/data/out/08SingleLine.out \
        < ./test/data/in/08SingleLine.in

    # Hier prüfen wir, dass das Skript ohne Fehler (Exit Code 0) durchgelaufen ist.
    assert_success

    # Da nur eine Zeile da ist, erwarten wir genau das Feld 2: 'only'.
    assert_output 'only'

    # Wir wollen keine Fehlermeldungen — also darf STDERR leer sein.
    [ -z "$stderr" ]

    # Zum Schluss vergleichen wir die komplette Ausgabedatei
    # mit unserer Erwartungsdatei. Alles muss 1:1 übereinstimmen.
    diff ./test/data/out/08SingleLine.out ./test/data/exp/08SingleLine.exp}

@test "09: Sonderzeichen in Feld 2 bleiben erhalten" {
    # Wir füttern das Skript mit unserer InputDatei und fangen STDERR separat ab
    run --separate-stderr "$DUT" ./test/data/out/09SpecialCharsTest.out \
        < ./test/data/in/09SpecialCharsTest.in

    # Check: Skript ist ohne Fehler durchgelaufen
    assert_success

    # Check: Auf STDOUT kam genau unser spezieller Unicode-String
    assert_output '©Ω≈ç'

    # Check: Keine unerwarteten Meldungen auf STDERR
    [ -z "$stderr" ]

    # Zum Schluss vergleichen wir die komplette Ausgabe-Datei
    # mit unserer Erwartungs-Datei  alles muss haargenau passen
    diff ./test/data/out/09SpecialCharsTest.out ./test/data/exp/09SpecialCharsTest.exp
}

@test "10: Zwei verschiedene Einträge → wählt kleineren Wert nach Feld 3" {
      # Wir führen unser Script ($DUT) aus, leiten den Input aus der Datei zu
      # und sammeln STDERR separat
    run --separate-stderr "$DUT" ./test/data/out/10PickMin.out \
        < ./test/data/in/10PickMin.in
   # Skript sollte ohne Fehler durchlaufen
    assert_success
   # Auf STDOUT erwarten wir 'foo' also das Feld 2 des Eintrags mit dem
    # kleineren Feld 3 (5 statt 10).
    assert_output 'foo'
   # Und natürlich darf kein Müll auf STDERR landen
    [ -z "$stderr" ]
       # Zum Schluss vergleichen wir die komplette Out Datei mit unserer
    # Referenz Datei. Wenn da was anders ist, meckert diff.
    diff ./test/data/out/10PickMin.out ./test/data/exp/10PickMin.exp
}
