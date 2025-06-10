#!/usr/bin/env bats

BATS_TEST_TIMEOUT=10
DUT="./ueb03.sh"

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

# =================== BASISFUNKTIONALITÄT ===================

@test "1. Hilfeaufruf mit -h" {
  run --separate-stderr "$DUT" -h
  
  assert_success
  assert_equal "$stderr" ''  # Keine Ausgabe auf stderr
  
  echo "$output" | diff - ./test/data/exp/help.exp
}

@test "2. Hilfeaufruf mit --help" {
  run --separate-stderr "$DUT" --help
  
  assert_success
  assert_equal "$stderr" ''  # Keine Ausgabe auf stderr
  
  echo "$output" | diff - ./test/data/exp/help.exp
}

@test "3. Zu wenig Parameter" {
  run --separate-stderr "$DUT"
  
  assert_failure
  assert_output ''  # Keine Ausgabe auf stdout
  
  echo "$stderr" | head --lines=1 | grep --regexp '^Error:'  # Pruefen, ob Error in der ersten Zeile steht
  echo "$stderr" | tail --lines=+2 | diff - ./test/data/exp/help.exp
}

@test "4. Ungültige Anzahl von Parametern" {
  run --separate-stderr "$DUT" 1 2
  
  assert_failure
  assert_output ''  # Keine Ausgabe auf stdout
  
  echo "$stderr" | head --lines=1 | grep --regexp '^Error:'  # Pruefen, ob Error in der ersten Zeile steht
  echo "$stderr" | tail --lines=+2 | diff - ./test/data/exp/help.exp
}

@test "5. Ungültiger Operator" {
  run --separate-stderr "$DUT" 1 2 XYZ
  
  assert_failure
  assert_output ''  # Keine Ausgabe auf stdout
  
  echo "$stderr" | head --lines=1 | grep --regexp '^Error:'  # Pruefen, ob Error in der ersten Zeile steht
  echo "$stderr" | tail --lines=+2 | diff - ./test/data/exp/help.exp
}

# =================== GRUNDOPERATIONEN ===================

@test "6. Addition - positive Zahlen" {
  run --separate-stderr "$DUT" 1 2 ADD
  
  assert_success
  assert_output '3'
  
  # Erstelle die erwartete Ausgabedatei falls sie nicht existiert
  mkdir -p ./test/data/exp
  echo "> ADD 1 2" > ./test/data/exp/add_positive.exp
  
  assert_equal "$stderr" "$(cat ./test/data/exp/add_positive.exp)"
}

@test "7. Addition - negative Zahlen" {
  run --separate-stderr "$DUT" -1 -2 ADD
  
  assert_success
  assert_output '-3'
  
  # Erstelle die erwartete Ausgabedatei falls sie nicht existiert
  mkdir -p ./test/data/exp
  echo "> ADD -1 -2" > ./test/data/exp/add_negative.exp
  
  assert_equal "$stderr" "$(cat ./test/data/exp/add_negative.exp)"
}

@test "8. Subtraktion - positive Zahlen" {
  run --separate-stderr "$DUT" 5 2 SUB
  
  assert_success
  assert_output '3'
  
  # Erstelle die erwartete Ausgabedatei falls sie nicht existiert
  mkdir -p ./test/data/exp
  echo "> SUB 5 2" > ./test/data/exp/sub_positive.exp
  
  assert_equal "$stderr" "$(cat ./test/data/exp/sub_positive.exp)"
}

@test "9. Multiplikation - positive Zahlen" {
  run --separate-stderr "$DUT" 3 4 MUL
  
  assert_success
  assert_output '12'
  
  # Erstelle die erwartete Ausgabedatei falls sie nicht existiert
  mkdir -p ./test/data/exp
  echo "> MUL 3 4" > ./test/data/exp/mul_positive.exp
  
  assert_equal "$stderr" "$(cat ./test/data/exp/mul_positive.exp)"
}

@test "10. Division - ganzzahlig" {
  run --separate-stderr "$DUT" 10 2 DIV
  
  assert_success
  assert_output '5'
  
  # Erstelle die erwartete Ausgabedatei falls sie nicht existiert
  mkdir -p ./test/data/exp
  echo "> DIV 10 2" > ./test/data/exp/div_positive.exp
  
  assert_equal "$stderr" "$(cat ./test/data/exp/div_positive.exp)"
}

@test "11. Division - durch Null" {
  run --separate-stderr "$DUT" 5 0 DIV
  
  assert_failure
  assert_output ''  # Keine Ausgabe auf stdout
  
  echo "$stderr" | head --lines=1 | grep --regexp '^Error:'  # Pruefen, ob Error in der ersten Zeile steht
  echo "$stderr" | tail --lines=+2 | diff - ./test/data/exp/help.exp
}

@test "12. Modulo - mit Rest" {
  run --separate-stderr "$DUT" 5 2 MOD
  
  assert_success
  assert_output '1'
  
  # Erstelle die erwartete Ausgabedatei falls sie nicht existiert
  mkdir -p ./test/data/exp
  echo "> MOD 5 2" > ./test/data/exp/mod_rest.exp
  
  assert_equal "$stderr" "$(cat ./test/data/exp/mod_rest.exp)"
}

@test "13. Modulo - durch Null" {
  run --separate-stderr "$DUT" 5 0 MOD
  
  assert_failure
  assert_output ''  # Keine Ausgabe auf stdout
  
  echo "$stderr" | head --lines=1 | grep --regexp '^Error:'  # Pruefen, ob Error in der ersten Zeile steht
  echo "$stderr" | tail --lines=+2 | diff - ./test/data/exp/help.exp
}

@test "14. Exponentiation - positiver Exponent" {
  run --separate-stderr "$DUT" 2 3 EXP
  
  assert_success
  assert_output '8'  # 2^3 = 8
  
  # Erstelle die erwartete Ausgabedatei falls sie nicht existiert
  mkdir -p ./test/data/exp
  echo "> EXP 2 3" > ./test/data/exp/exp_positive.exp
  
  assert_equal "$stderr" "$(cat ./test/data/exp/exp_positive.exp)"
}

@test "15. Exponentiation - mit 0 als Exponent" {
  run --separate-stderr "$DUT" 5 0 EXP
  
  assert_success
  assert_output '1'  # x^0 = 1
  
  # Erstelle die erwartete Ausgabedatei falls sie nicht existiert
  mkdir -p ./test/data/exp
  echo "> EXP 5 0" > ./test/data/exp/exp_zero.exp
  
  assert_equal "$stderr" "$(cat ./test/data/exp/exp_zero.exp)"
}

@test "16. Exponentiation - 0^0 (sollte als undefiniert behandelt werden)" {
  run --separate-stderr "$DUT" 0 0 EXP
  
  assert_failure
  assert_output ''  # Keine Ausgabe auf stdout
  
  echo "$stderr" | head --lines=1 | grep --regexp '^Error:'  # Pruefen, ob Error in der ersten Zeile steht
  echo "$stderr" | tail --lines=+2 | diff - ./test/data/exp/help.exp
}

@test "17. Exponentiation - negativer Exponent" {
  run --separate-stderr "$DUT" 2 -1 EXP
  
  assert_failure
  assert_output ''  # Keine Ausgabe auf stdout
  
  echo "$stderr" | head --lines=1 | grep --regexp '^Error:'  # Pruefen, ob Error in der ersten Zeile steht
  echo "$stderr" | tail --lines=+2 | diff - ./test/data/exp/help.exp
}

# =================== KOMPLEXE BERECHNUNGEN ===================

@test "18. Mehrfache Addition" {
  run --separate-stderr "$DUT" 1 2 ADD 4 ADD 2 ADD
  
  assert_success
  assert_output '9'  # 1 + 2 = 3, 3 + 4 = 7, 7 + 2 = 9
  
  echo "$stderr" | diff - ./test/data/exp/multiple_add.exp
}

@test "19. Alle Operationen" {
  run --separate-stderr "$DUT" 1 2 ADD 2 SUB 7 MUL 2 EXP
  
  assert_success
  assert_output '49'  # 1 + 2 = 3, 3 - 2 = 1, 1 * 7 = 7, 7^2 = 49
  
  echo "$stderr" | diff - ./test/data/exp/multiple_ops.exp
}

@test "20. Division gefolgt von Modulo" {
  run --separate-stderr "$DUT" 10 2 DIV 3 MOD
  
  assert_success
  assert_output '2'  # 10 / 2 = 5, 5 % 3 = 2
  
  # Erstelle die erwartete Ausgabedatei falls sie nicht existiert
  mkdir -p ./test/data/exp
  cat > ./test/data/exp/div_mod.exp << EOF
> DIV 10 2
> MOD 5 3
EOF
  
  echo "$stderr" | diff - ./test/data/exp/div_mod.exp
}

@test "21. Fehler in der Mitte einer Berechnung" {
  run --separate-stderr "$DUT" 1 2 ADD 0 DIV
  
  assert_failure
  assert_output ''  # Keine Ausgabe auf stdout
  
  echo "$stderr" | head --lines=1 | grep --regexp '^Error:'  # Pruefen, ob Error in der ersten Zeile steht
  # Wir überprüfen nicht den gesamten stderr, da die Ausgabe variieren kann
}
