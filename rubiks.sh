#!/bin/bash

# --------------------------------------
# Configuration
# --------------------------------------
CSV_FILE="reactiontime.csv"
R_SCRIPT="rubiks.R"
PDF_FILE="rubiks.pdf"

# --------------------------------------
# Initialize CSV file
# Create file with header if it does not exist
# --------------------------------------
initialize_csv() {
    if [ ! -f "$CSV_FILE" ]; then
        echo "date,time,reaction_time" > "$CSV_FILE"
    fi
}

# --------------------------------------
# Wait until user presses spacebar
# --------------------------------------
wait_for_spacebar() {
    while true; do
        IFS= read -rsn1 key
        if [[ "$key" == " " ]]; then
            break
        fi
    done
}

# --------------------------------------
# Display program header
# --------------------------------------
show_header() {
    clear
    echo "        Rubik's Cube Trainer"
    echo "=================================="
    echo "Press [SPACE] to start..."
}

# --------------------------------------
# Start timer
# --------------------------------------
start_timer() {
    start_time=$(date +%s%N)
}

# --------------------------------------
# Stop timer
# --------------------------------------
stop_timer() {
    end_time=$(date +%s%N)
}

# --------------------------------------
# Calculate elapsed time in seconds
# --------------------------------------
calculate_elapsed_time() {
    elapsed_ns=$((end_time - start_time))
    elapsed_s=$(echo "scale=3; $elapsed_ns / 1000000000" | bc)
}

# --------------------------------------
# Save result to CSV
# --------------------------------------
save_result() {
    current_date=$(date +%Y-%m-%d)
    current_time=$(date +%H:%M:%S)

    echo "$current_date,$current_time,$elapsed_s" >> "$CSV_FILE"
}

# --------------------------------------
# Run R analysis script
# --------------------------------------
run_analysis() {
    echo "Preparing analysis..."
    Rscript "$R_SCRIPT"

    echo "Analysis completed."
}

# --------------------------------------
# Open generated PDF report
# --------------------------------------
open_report() {
    echo "Opening PDF report..."
    xdg-open "$PDF_FILE"
}

# --------------------------------------
# Main program flow
# --------------------------------------
main() {
    initialize_csv
    show_header

    wait_for_spacebar

    start_timer
    echo "Timer running... Press [SPACE] again to stop."

    wait_for_spacebar

    stop_timer
    calculate_elapsed_time
    save_result

    echo
    echo "Reaction time: $elapsed_s seconds"
    echo "Result saved to $CSV_FILE"

    run_analysis
    open_report
}

# Execute program
main
