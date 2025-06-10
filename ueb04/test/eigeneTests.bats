#!/usr/bin/env bats
# eigeneTests.bats - Tests für das ueb04 Script
# Testet das bestehende ueb04 Script mit den vorhandenen Test-Dateien

# Setup-Funktion wird vor jedem Test ausgeführt
setup() {
    # Pfade zum Script und Test-Daten
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    UEBUNG_SCRIPT="$PROJECT_ROOT/ueb04"
    
    # Sicherstellen dass Script ausführbar ist
    chmod +x "$UEBUNG_SCRIPT"
    
    # Test-Daten-Pfade (verwende vorhandene Test-Dateien falls vorhanden)
    TEST_DATA_DIR="$SCRIPT_DIR/data"
    
    # Falls keine Test-Daten vorhanden, erstelle minimal nötige
    if [ ! -d "$TEST_DATA_DIR" ]; then
        mkdir -p "$TEST_DATA_DIR"
        create_minimal_test_files
    fi
}

# Minimale Test-Dateien erstellen falls nicht vorhanden
create_minimal_test_files() {
    # Basis-Test-Datei
    cat > "$TEST_DATA_DIR/simple.tex" << 'EOF'
\documentclass{article}
\usepackage[T1]{fontenc}
\usepackage{amsmath}
\usepackage[colorlinks,citecolor=black]{hyperref}

\begin{document}
\chapter{Introduction}
\section{First Section}
\includegraphics[width=\textwidth]{image1}
\subsection{Subsection One}
\includegraphics{folder/image2}
\end{document}
EOF

    # Test-Datei mit Kommentaren
    cat > "$TEST_DATA_DIR/comments.tex" << 'EOF'
% Dies ist ein Kommentar \includegraphics{fake_image}
\includegraphics{real_image1} % Kommentar am Ende \includegraphics{fake_image2}
% \chapter{Fake Chapter}
\chapter{Real Chapter} % \section{Fake Section}
% \usepackage{fake_package}
\usepackage{real_package} % \usepackage{another_fake}
EOF

    # Leere Test-Datei
    touch "$TEST_DATA_DIR/empty.tex"
}

# =============================================================================
# HILFE-TESTS
# =============================================================================

@test "ueb04: Hilfe mit -h funktioniert" {
    run "$UEBUNG_SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "prints this help and exits" ]]
    [[ "$output" =~ "-g, --graphics" ]]
    [[ "$output" =~ "-s, --structure" ]]
    [[ "$output" =~ "-u, --usedpackages" ]]
}

@test "ueb04: Hilfe mit --help funktioniert" {
    run "$UEBUNG_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "ueb04: Hilfe hat korrekte Formatierung" {
    run "$UEBUNG_SCRIPT" -h
    [ "$status" -eq 0 ]
    # Prüfe auf spezifische Formatierung
    [[ "$output" =~ "  ueb04 -h | ueb04 --help" ]]
    [[ "$output" =~ "  - or -" ]]
    [[ "$output" =~ "  ueb04 INPUT OPTION" ]]
}

@test "ueb04: Hilfe mit zusätzlichen Argumenten schlägt fehl" {
    run "$UEBUNG_SCRIPT" -h extra_arg
    [ "$status" -gt 0 ]
    [[ "$output" =~ "Error:" ]]
}

# =============================================================================
# FEHLERBEHANDLUNG
# =============================================================================

@test "ueb04: Keine Argumente führt zu Fehler" {
    run "$UEBUNG_SCRIPT"
    [ "$status" -gt 0 ]
    [[ "$output" =~ "Error:" ]]
    [[ "$output" =~ "Usage:" ]]
}

@test "ueb04: Nur ein Argument führt zu Fehler" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex"
    [ "$status" -gt 0 ]
    [[ "$output" =~ "Error:" ]]
}

@test "ueb04: Zu viele Argumente führt zu Fehler" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -g extra
    [ "$status" -gt 0 ]
    [[ "$output" =~ "Error:" ]]
}

@test "ueb04: Nicht existierende Datei führt zu Fehler" {
    run "$UEBUNG_SCRIPT" "/tmp/nonexistent_file.tex" -g
    [ "$status" -gt 0 ]
    [[ "$output" =~ "Error:" ]]
}

@test "ueb04: Datei ohne .tex Endung führt zu Fehler" {
    echo "test" > /tmp/test_file.txt
    run "$UEBUNG_SCRIPT" "/tmp/test_file.txt" -g
    [ "$status" -gt 0 ]
    [[ "$output" =~ "Error:" ]]
    rm -f /tmp/test_file.txt
}

@test "ueb04: Unbekannte Option führt zu Fehler" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -x
    [ "$status" -gt 0 ]
    [[ "$output" =~ "Error:" ]]
}

@test "ueb04: Fehlerausgabe geht an stderr" {
    run bash -c "'$UEBUNG_SCRIPT' 2>&1 >/dev/null"
    [ "$status" -gt 0 ]
    [[ "$output" =~ "Error:" ]]
}

# =============================================================================
# GRAPHICS-FUNKTIONALITÄT
# =============================================================================

@test "ueb04: Graphics-Extraktion funktioniert mit -g" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -g
    [ "$status" -eq 0 ]
    [[ "$output" =~ "image1" ]]
    [[ "$output" =~ "folder/image2" ]]
}

@test "ueb04: Graphics-Extraktion funktioniert mit --graphics" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" --graphics
    [ "$status" -eq 0 ]
    [[ "$output" =~ "image1" ]]
}

@test "ueb04: Graphics ignoriert Kommentare" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/comments.tex" -g
    [ "$status" -eq 0 ]
    [[ "$output" =~ "real_image1" ]]
    [[ ! "$output" =~ "fake_image" ]]
}

@test "ueb04: Graphics mit leerer Datei gibt keine Ausgabe" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/empty.tex" -g
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "ueb04: Graphics ignoriert Optionen in eckigen Klammern" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -g
    [ "$status" -eq 0 ]
    # Sollte nur Dateinamen enthalten, keine Optionen
    [[ ! "$output" =~ "width" ]]
    [[ ! "$output" =~ "textwidth" ]]
}

# =============================================================================
# STRUCTURE-FUNKTIONALITÄT
# =============================================================================

@test "ueb04: Structure-Extraktion funktioniert mit -s" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Introduction" ]]
    [[ "$output" =~ "|-- First Section" ]]
    [[ "$output" =~ "    |-- Subsection One" ]]
}

@test "ueb04: Structure-Extraktion funktioniert mit --structure" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" --structure
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Introduction" ]]
}

@test "ueb04: Structure ignoriert Kommentare" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/comments.tex" -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Real Chapter" ]]
    [[ ! "$output" =~ "Fake Chapter" ]]
}

@test "ueb04: Structure hat korrekte Einrückung" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -s
    [ "$status" -eq 0 ]
    # Section beginnt mit "|-- "
    echo "$output" | grep -q "^|-- First Section"
    # Subsection beginnt mit "    |-- "
    echo "$output" | grep -q "^    |-- Subsection One"
}

@test "ueb04: Structure mit leerer Datei gibt keine Ausgabe" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/empty.tex" -s
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "ueb04: Structure behandelt Sterne-Befehle" {
    # Erstelle temporäre Datei mit Sterne-Befehlen
    cat > /tmp/stars.tex << 'EOF'
\chapter{Normal Chapter}
\chapter*{Starred Chapter}
\section{Normal Section}
\section*{Starred Section}
\subsection{Normal Subsection}
\subsection*{Starred Subsection}
EOF
    
    run "$UEBUNG_SCRIPT" /tmp/stars.tex -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Normal Chapter" ]]
    [[ "$output" =~ "Starred Chapter" ]]
    [[ "$output" =~ "|-- Normal Section" ]]
    [[ "$output" =~ "|-- Starred Section" ]]
    [[ "$output" =~ "    |-- Normal Subsection" ]]
    [[ "$output" =~ "    |-- Starred Subsection" ]]
    
    rm -f /tmp/stars.tex
}

# =============================================================================
# PACKAGES-FUNKTIONALITÄT
# =============================================================================

@test "ueb04: Package-Extraktion funktioniert mit -u" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -u
    [ "$status" -eq 0 ]
    [[ "$output" =~ "amsmath:" ]]
    [[ "$output" =~ "fontenc:T1" ]]
    [[ "$output" =~ "hyperref:colorlinks,citecolor=black" ]]
}

@test "ueb04: Package-Extraktion funktioniert mit --usedpackages" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" --usedpackages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "amsmath:" ]]
}

@test "ueb04: Packages sind alphabetisch sortiert" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -u
    [ "$status" -eq 0 ]
    # Erste Zeile sollte amsmath sein (alphabetisch erste)
    first_line=$(echo "$output" | head -n1)
    [[ "$first_line" =~ ^amsmath: ]]
}

@test "ueb04: Package-Output enthält keine Leerzeichen" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -u
    [ "$status" -eq 0 ]
    # Prüfe dass keine unerwünschten Leerzeichen vorhanden sind
    ! echo "$output" | grep -q " ,"
    ! echo "$output" | grep -q ", "
    ! echo "$output" | grep -q " :"
}

@test "ueb04: Packages ignoriert Kommentare" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/comments.tex" -u
    [ "$status" -eq 0 ]
    [[ "$output" =~ "real_package:" ]]
    [[ ! "$output" =~ "fake_package" ]]
    [[ ! "$output" =~ "another_fake" ]]
}

@test "ueb04: Packages mit leerer Datei gibt keine Ausgabe" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/empty.tex" -u
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "ueb04: Packages behandelt Multiline-Strukturen" {
    # Erstelle temporäre Datei mit Multiline-Paketen
    cat > /tmp/multiline.tex << 'EOF'
\usepackage[
  colorlinks,
  citecolor=black,
  filecolor=blue
]{hyperref}

\usepackage[
utf8
]{inputenc}
EOF
    
    run "$UEBUNG_SCRIPT" /tmp/multiline.tex -u
    [ "$status" -eq 0 ]
    [[ "$output" =~ "hyperref:colorlinks,citecolor=black,filecolor=blue" ]]
    [[ "$output" =~ "inputenc:utf8" ]]
    
    rm -f /tmp/multiline.tex
}

@test "ueb04: Packages ohne Optionen werden korrekt behandelt" {
    # Erstelle temporäre Datei mit Paketen ohne Optionen
    cat > /tmp/no_options.tex << 'EOF'
\usepackage{amsmath}
\usepackage{geometry}
EOF
    
    run "$UEBUNG_SCRIPT" /tmp/no_options.tex -u
    [ "$status" -eq 0 ]
    [[ "$output" =~ "amsmath:" ]]
    [[ "$output" =~ "geometry:" ]]
    
    rm -f /tmp/no_options.tex
}

# =============================================================================
# EXIT-CODE TESTS
# =============================================================================

@test "ueb04: Exit-Code 0 für erfolgreiche Hilfe" {
    run "$UEBUNG_SCRIPT" -h
    [ "$status" -eq 0 ]
}

@test "ueb04: Exit-Code 0 für erfolgreiche Ausführung" {
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -g
    [ "$status" -eq 0 ]
}

@test "ueb04: Exit-Code >0 für Fehler" {
    run "$UEBUNG_SCRIPT" "/tmp/nonexistent.tex" -g
    [ "$status" -gt 0 ]
}

@test "ueb04: Exit-Code >0 für falsche Argumente" {
    run "$UEBUNG_SCRIPT"
    [ "$status" -gt 0 ]
}

# =============================================================================
# EDGE CASES UND SPEZIALFÄLLE
# =============================================================================

@test "ueb04: Behandlung von escaped Percent-Zeichen" {
    cat > /tmp/escaped.tex << 'EOF'
\chapter{Title with \% percent}
\includegraphics{file\%name}
EOF
    
    run "$UEBUNG_SCRIPT" /tmp/escaped.tex -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Title with % percent" ]]
    
    run "$UEBUNG_SCRIPT" /tmp/escaped.tex -g
    [ "$status" -eq 0 ]
    [[ "$output" =~ "file%name" ]]
    
    rm -f /tmp/escaped.tex
}

@test "ueb04: Kommentare am Zeilenanfang werden ignoriert" {
    cat > /tmp/line_comments.tex << 'EOF'
% \includegraphics{should_not_appear}
\includegraphics{should_appear}
% Complete comment line with \chapter{fake}
\chapter{real}
EOF
    
    run "$UEBUNG_SCRIPT" /tmp/line_comments.tex -g
    [ "$status" -eq 0 ]
    [[ "$output" =~ "should_appear" ]]
    [[ ! "$output" =~ "should_not_appear" ]]
    
    run "$UEBUNG_SCRIPT" /tmp/line_comments.tex -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ "real" ]]
    [[ ! "$output" =~ "fake" ]]
    
    rm -f /tmp/line_comments.tex
}

@test "ueb04: Multiple Befehle pro Zeile werden erkannt" {
    cat > /tmp/multiple.tex << 'EOF'
\chapter{A}\section{B}\subsection{C}
\includegraphics{img1}\includegraphics{img2}
EOF
    
    run "$UEBUNG_SCRIPT" /tmp/multiple.tex -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ "A" ]]
    [[ "$output" =~ "|-- B" ]]
    [[ "$output" =~ "    |-- C" ]]
    
    run "$UEBUNG_SCRIPT" /tmp/multiple.tex -g
    [ "$status" -eq 0 ]
    [[ "$output" =~ "img1" ]]
    [[ "$output" =~ "img2" ]]
    
    rm -f /tmp/multiple.tex
}

@test "ueb04: Leere Klammern werden korrekt behandelt" {
    cat > /tmp/empty_braces.tex << 'EOF'
\usepackage[]{}
\usepackage{normal_package}
\chapter{}
\section{Normal Section}
\includegraphics{}
\includegraphics{normal_image}
EOF
    
    run "$UEBUNG_SCRIPT" /tmp/empty_braces.tex -u
    [ "$status" -eq 0 ]
    [[ "$output" =~ "normal_package:" ]]
    
    run "$UEBUNG_SCRIPT" /tmp/empty_braces.tex -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ "|-- Normal Section" ]]
    
    run "$UEBUNG_SCRIPT" /tmp/empty_braces.tex -g
    [ "$status" -eq 0 ]
    [[ "$output" =~ "normal_image" ]]
    
    rm -f /tmp/empty_braces.tex
}

@test "ueb04: Keine temporären Dateien werden zurückgelassen" {
    temp_before=$(find /tmp -name "tmp.*" 2>/dev/null | wc -l)
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -u
    [ "$status" -eq 0 ]
    temp_after=$(find /tmp -name "tmp.*" 2>/dev/null | wc -l)
    [ "$temp_before" -eq "$temp_after" ]
}

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

@test "ueb04: Alle Optionen funktionieren mit derselben Datei" {
    # Test dass alle drei Hauptfunktionen mit derselben Datei funktionieren
    
    # Graphics
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -g
    [ "$status" -eq 0 ]
    [[ "$output" =~ "image1" ]]
    
    # Structure  
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Introduction" ]]
    
    # Packages
    run "$UEBUNG_SCRIPT" "$TEST_DATA_DIR/simple.tex" -u
    [ "$status" -eq 0 ]
    [[ "$output" =~ "amsmath:" ]]
}

@test "ueb04: Robustheit bei komplexen LaTeX-Strukturen" {
    # Erstelle eine komplexe Test-Datei
    cat > /tmp/complex.tex << 'EOF'
\documentclass{article}
\usepackage[T1]{fontenc}
\usepackage[colorlinks,citecolor=black,filecolor=blue]{hyperref}
\usepackage{amsmath}
\usepackage{geometry}

\begin{document}
% Kommentar mit \chapter{Fake Chapter}
\chapter{Real Chapter One}
\includegraphics[width=\textwidth]{images/main_image} % \includegraphics{fake_image}

\section{Important Section}
\includegraphics{data/chart}

\subsection{Details}
% \includegraphics{commented_out}
\includegraphics{final/result}

\chapter*{Appendix}
\section*{References}
\subsection*{Notes}

% \usepackage{fake_package}
\end{document}
EOF
    
    # Test alle Funktionen mit der komplexen Datei
    run "$UEBUNG_SCRIPT" /tmp/complex.tex -g
    [ "$status" -eq 0 ]
    [[ "$output" =~ "images/main_image" ]]
    [[ "$output" =~ "data/chart" ]]
    [[ "$output" =~ "final/result" ]]
    [[ ! "$output" =~ "fake_image" ]]
    [[ ! "$output" =~ "commented_out" ]]
    
    run "$UEBUNG_SCRIPT" /tmp/complex.tex -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Real Chapter One" ]]
    [[ "$output" =~ "|-- Important Section" ]]
    [[ "$output" =~ "    |-- Details" ]]
    [[ "$output" =~ "Appendix" ]]
    [[ "$output" =~ "|-- References" ]]
    [[ "$output" =~ "    |-- Notes" ]]
    [[ ! "$output" =~ "Fake Chapter" ]]
    
    run "$UEBUNG_SCRIPT" /tmp/complex.tex -u
    [ "$status" -eq 0 ]
    [[ "$output" =~ "amsmath:" ]]
    [[ "$output" =~ "fontenc:T1" ]]
    [[ "$output" =~ "geometry:" ]]
    [[ "$output" =~ "hyperref:colorlinks,citecolor=black,filecolor=blue" ]]
    [[ ! "$output" =~ "fake_package" ]]
    
    rm -f /tmp/complex.tex
}