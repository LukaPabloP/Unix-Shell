#!/usr/bin/env bats

BATS_TEST_TIMEOUT=30
DUT="Makefile"

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
    
    # Arbeitsverzeichnis für Tests erstellen
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Makefile kopieren
    cp "$OLDPWD/$DUT" .
    
    # Testdateien erstellen (leere Dateien reichen für Tests)
    touch test1.jpg test2.tga test3.ppm existing.png
}

teardown() {
    # Aufräumen
    cd "$OLDPWD"
    rm -rf "$TEST_DIR"
    
    # Ausgabe des Aufrufs bei fehlgeschlagenen Testfällen
    echo "Aufruf: $BATS_RUN_COMMAND"
}

# =================== HILFE-TARGET ===================

@test "1. Help-Target zeigt korrekte Hilfe" {
    run make --file="$DUT" help
    
    assert_success
    assert_line --partial "Makefile which scales and converts jpg, tga and ppm files to png and generates an archive"
    assert_line --partial "VARIABLES"
    assert_line --partial "SIZE     - specifies the largest image size (default=100)"
    assert_line --partial "TARGETS"
    assert_line --partial "all      - default target, does the same as tar target"
    assert_line --partial "archive  - scale and convert all jpg, tga and ppm files to png and create an archive.tgz"
    assert_line --partial "png      - scale and convert all jpg, tga and ppm files to png"
    assert_line --partial "help     - display this help and exit"
    assert_line --partial "clean    - remove all generated files"
}

# =================== CLEAN-TARGET ===================

@test "2. Clean-Target entfernt generierte Dateien" {
    # Simuliere generierte Dateien
    touch test1.ppm test2.ppm test1.scaled test2.scaled test1.png test2.png archive.tgz
    
    run make --file="$DUT" clean
    
    assert_success
    
    # Generierte Dateien sollten gelöscht sein
    assert_not_exists test1.ppm
    assert_not_exists test2.ppm
    assert_not_exists test1.scaled
    assert_not_exists test2.scaled
    assert_not_exists test1.png
    assert_not_exists test2.png
    assert_not_exists archive.tgz
    
    # Ursprüngliche Dateien sollten noch existieren
    assert_exists test1.jpg
    assert_exists test2.tga
    assert_exists test3.ppm
    assert_exists existing.png
}

@test "3. Clean-Target bei leinem Verzeichnis" {
    # Alle Testdateien entfernen
    rm -f *.jpg *.tga *.ppm *.png
    
    run make --file="$DUT" clean
    
    assert_success
}

# =================== PATTERN RULES ===================

@test "4. JPG zu PPM Konvertierung" {
    # Simuliere jpegtopnm Programm
    cat > jpegtopnm << 'EOF'
#!/bin/bash
echo "Converted $1 to PPM format"
EOF
    chmod +x jpegtopnm
    export PATH=".:$PATH"
    
    run make --file="$DUT" test1.ppm
    
    assert_success
    assert_exists test1.ppm
}

@test "5. TGA zu PPM Konvertierung" {
    # Simuliere tgatoppm Programm
    cat > tgatoppm << 'EOF'
#!/bin/bash
echo "Converted $1 to PPM format"
EOF
    chmod +x tgatoppm
    export PATH=".:$PATH"
    
    run make --file="$DUT" test2.ppm
    
    assert_success
    assert_exists test2.ppm
}

@test "6. PPM Skalierung mit Standard-SIZE" {
    # Simuliere pnmscale Programm
    cat > pnmscale << 'EOF'
#!/bin/bash
echo "Scaled to $2 $3 from $4"
EOF
    chmod +x pnmscale
    export PATH=".:$PATH"
    
    # Erstelle PPM-Datei
    echo "P3 10 10 255" > test3.ppm
    
    run make --file="$DUT" test3.scaled
    
    assert_success
    assert_exists test3.scaled
}

@test "7. PPM Skalierung mit benutzerdefinierter SIZE" {
    # Simuliere pnmscale Programm
    cat > pnmscale << 'EOF'
#!/bin/bash
echo "Scaled to $2 $3 from $4"
EOF
    chmod +x pnmscale
    export PATH=".:$PATH"
    
    # Erstelle PPM-Datei
    echo "P3 10 10 255" > test3.ppm
    
    run make --file="$DUT" SIZE=250 test3.scaled
    
    assert_success
    assert_exists test3.scaled
}

@test "8. PNG Konvertierung" {
    # Simuliere pnmtopng Programm
    cat > pnmtopng << 'EOF'
#!/bin/bash
echo "Converted to PNG"
EOF
    chmod +x pnmtopng
    export PATH=".:$PATH"
    
    # Erstelle scaled-Datei
    echo "scaled image data" > test1.scaled
    
    run make --file="$DUT" test1.png
    
    assert_success
    assert_exists test1.png
}

# =================== PNG-TARGET ===================

@test "9. PNG-Target konvertiert alle Bilder" {
    # Simuliere alle benötigten Programme
    for prog in jpegtopnm tgatoppm pnmscale pnmtopng; do
        cat > $prog << 'EOF'
#!/bin/bash
echo "Processing with $0"
EOF
        chmod +x $prog
    done
    export PATH=".:$PATH"
    
    run make --file="$DUT" png
    
    assert_success
    # PNG-Dateien sollten erstellt werden
    assert_exists test1.png
    assert_exists test2.png
    assert_exists test3.png
}

@test "10. PNG-Target bei leinem Verzeichnis" {
    # Alle Bilddateien entfernen
    rm -f *.jpg *.tga *.ppm
    
    run make --file="$DUT" png
    
    assert_success
}

# =================== ARCHIVE-TARGET ===================

@test "11. Archive-Target erstellt TGZ-Archiv" {
    # Simuliere alle benötigten Programme
    for prog in jpegtopnm tgatoppm pnmscale pnmtopng; do
        cat > $prog << 'EOF'
#!/bin/bash
echo "Processing with $0"
EOF
        chmod +x $prog
    done
    
    # Simuliere tar Programm
    cat > tar << 'EOF'
#!/bin/bash
echo "Creating archive with: $@"
touch archive.tgz
EOF
    chmod +x tar
    export PATH=".:$PATH"
    
    run make --file="$DUT" archive
    
    assert_success
    assert_exists archive.tgz
}

@test "12. Archive.tgz Target funktioniert direkt" {
    # Simuliere alle benötigten Programme
    for prog in jpegtopnm tgatoppm pnmscale pnmtopng; do
        cat > $prog << 'EOF'
#!/bin/bash
echo "Processing with $0"
EOF
        chmod +x $prog
    done
    
    # Simuliere tar Programm
    cat > tar << 'EOF'
#!/bin/bash
echo "Creating archive with: $@"
touch archive.tgz
EOF
    chmod +x tar
    export PATH=".:$PATH"
    
    run make --file="$DUT" archive.tgz
    
    assert_success
    assert_exists archive.tgz
}

# =================== ALL-TARGET ===================

@test "13. All-Target (Standard) erstellt Archiv" {
    # Simuliere alle benötigten Programme
    for prog in jpegtopnm tgatoppm pnmscale pnmtopng; do
        cat > $prog << 'EOF'
#!/bin/bash
echo "Processing with $0"
EOF
        chmod +x $prog
    done
    
    # Simuliere tar Programm
    cat > tar << 'EOF'
#!/bin/bash
echo "Creating archive with: $@"
touch archive.tgz
EOF
    chmod +x tar
    export PATH=".:$PATH"
    
    run make --file="$DUT" all
    
    assert_success
    assert_exists archive.tgz
}

@test "14. Make ohne Target funktioniert (Standard)" {
    # Simuliere alle benötigten Programme
    for prog in jpegtopnm tgatoppm pnmscale pnmtopng; do
        cat > $prog << 'EOF'
#!/bin/bash
echo "Processing with $0"
EOF
        chmod +x $prog
    done
    
    # Simuliere tar Programm
    cat > tar << 'EOF'
#!/bin/bash
echo "Creating archive with: $@"
touch archive.tgz
EOF
    chmod +x tar
    export PATH=".:$PATH"
    
    run make --file="$DUT"
    
    assert_success
    assert_exists archive.tgz
}

# =================== ABHÄNGIGKEITEN ===================

@test "15. Dateien werden nur bei Bedarf neu erstellt" {
    # Simuliere alle benötigten Programme
    for prog in jpegtopnm tgatoppm pnmscale pnmtopng; do
        cat > $prog << 'EOF'
#!/bin/bash
echo "Processing $@ at $(date)"
EOF
        chmod +x $prog
    done
    export PATH=".:$PATH"
    
    # Erste Ausführung
    make --file="$DUT" test1.png > /dev/null 2>&1
    
    # Zeitstempel merken
    timestamp1=$(stat -c %Y test1.png 2>/dev/null || echo "0")
    
    sleep 1
    
    # Zweite Ausführung - sollte nichts machen
    run make --file="$DUT" test1.png
    
    assert_success
    assert_output --partial "is up to date"
    
    # Zeitstempel sollte gleich sein
    timestamp2=$(stat -c %Y test1.png 2>/dev/null || echo "0")
    assert_equal "$timestamp1" "$timestamp2"
}

@test "16. SIZE-Variable wird korrekt verwendet" {
    # Simuliere pnmscale das die Parameter ausgibt
    cat > pnmscale << 'EOF'
#!/bin/bash
echo "SIZE: $2 $3" >&2
echo "scaled image"
EOF
    chmod +x pnmscale
    export PATH=".:$PATH"
    
    # Erstelle PPM-Datei
    echo "P3 10 10 255" > test.ppm
    
    run --separate-stderr make --file="$DUT" SIZE=200 test.scaled
    
    assert_success
    assert_line --stderr "SIZE: 200 200"
}

# =================== FEHLERBEHANDLUNG ===================

@test "17. Ungültiges Target gibt Fehler" {
    run make --file="$DUT" ungueltig
    
    assert_failure
    assert_output --partial "No rule to make target"
}

@test "18. .SECONDARY verhindert Löschung von Zwischendateien" {
    # Simuliere alle benötigten Programme
    for prog in jpegtopnm tgatoppm pnmscale pnmtopng; do
        cat > $prog << 'EOF'
#!/bin/bash
echo "processed"
EOF
        chmod +x $prog
    done
    export PATH=".:$PATH"
    
    # PNG erstellen
    make --file="$DUT" test1.png > /dev/null 2>&1
    
    # Zwischendateien sollten noch existieren
    assert_exists test1.ppm
    assert_exists test1.scaled
}
