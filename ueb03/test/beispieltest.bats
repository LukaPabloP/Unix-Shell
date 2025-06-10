BATS_TEST_TIMEOUT=10

setup_file() {
    # sichergehen, dass $DUT gesetzt ist
    if [ -z ${DUT+x} ]; then
        echo 'DUT not set'
        exit
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
    # Ausgabe des Aufrufs bei fehlgeschlagenen Testfaellen
    echo "Aufruf: $BATS_RUN_COMMAND"
}


@test "1. Hilfeaufruf, Beispieltest" {

    # Kurzform:
    run --separate-stderr "$DUT" -h

    assert_success # nach "-h"
    assert_equal "$stderr" '' # Es darf keine Ausgabe auf stderr geben (nach "-h")

    echo "$output" | diff - ./test/data/exp/help.exp # nach "-h"

    # Langform:
    run --separate-stderr "$DUT" --help

    assert_success # nach "--help"
    assert_equal "$stderr" '' # Es darf keine Ausgabe auf stderr geben (nach "--help")

    echo "$output" | diff - ./test/data/exp/help.exp # nach "--help"
}

@test "2. Einfache Addition, Beispieltest" {

    run --separate-stderr "$DUT" 1 2 ADD

    assert_success
    assert_output '3'

    assert_equal "$stderr" '> ADD 1 2'
}

@test "3. Einfache Addition, negative Zahlen, negatives Ergebnis, Beispieltest" {

    run --separate-stderr "$DUT" -1 -2 ADD

    assert_success
    assert_output '-3'

    assert_equal "$stderr" '> ADD -1 -2'
}

@test "4. Mehrfache Addition, Beispieltest" {

    run --separate-stderr "$DUT" 1 2 ADD 4 ADD 2 ADD

    assert_success
    assert_output '9'

    echo "$stderr" | diff - ./test/data/exp/multiple_add.exp
}

@test "5. Alle Operationen, außer DIV und MOD, Beispieltest" {

    run --separate-stderr "$DUT" 1 2 ADD 2 SUB 7 MUL 2 EXP

    assert_success
    assert_output '49'

    echo "$stderr" | diff - ./test/data/exp/multiple_ops.exp
}

@test "6. Fehler: keine Parameter, Beispieltest" {

    run --separate-stderr "$DUT"

    assert_failure
    assert_output '' # Es darf keine Ausgabe auf stdout geben

    echo "$stderr" | head --lines=1 | grep --regexp '^Error:' # Pruefen, ob Error in der ersten Zeile steht
    echo "$stderr" | tail --lines=+2 | diff - ./test/data/exp/help.exp
}
