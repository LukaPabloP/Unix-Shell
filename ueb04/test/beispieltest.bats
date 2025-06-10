#!/usr/bin/env bats
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
    echo "Aufruf: $BATS_RUN_COMMAND"
    echo "Exit-Code: $status"
}


@test "1. Hilfeaufruf" {
    # Kurzform:
    run --separate-stderr "$DUT" -h

    echo "$output" | diff --binary ./test/data/exp/usage.exp -  # nach "-h"
    [ -z "$stderr" ]  # nach "-h"
    assert_success  # nach "-h"

    # Langform:
    run --separate-stderr "$DUT" --help

    echo "$output" | diff --binary ./test/data/exp/usage.exp -  # nach "--help"
    [ -z "$stderr" ]  # nach "--help"
    assert_success  # nach "--help"
}

@test "2. Includegraphics-Ausgabe für Latex_Mini_Dummy.tex" {
    run --separate-stderr "$DUT" ./test/data/in/Latex_Mini_Dummy.tex -g

    assert_output 'imgfoo
imgfoo'

    [ -z "$stderr" ]
    assert_success
}

@test "3. Structure-Ausgabe für Latex_Mini_Dummy.tex" {
    run --separate-stderr "$DUT" ./test/data/in/Latex_Mini_Dummy.tex -s

    echo "$output" | diff --binary ./test/data/exp/bsp.exp -

    [ -z "$stderr" ]
    assert_success
}

@test "4. Usepackage-Ausgabe für Latex_Mini_Dummy.tex" {
    run --separate-stderr "$DUT" ./test/data/in/Latex_Mini_Dummy.tex -u

    assert_output 'fontenc:T1
graphicx:'

    [ -z "$stderr" ]
    assert_success
}
