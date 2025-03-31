# 🧮 MIPS Linear Equation Solver

A MIPS Assembly program that solves systems of linear equations (2x2 or 3x3) using **Cramer's Rule**. The program reads from a user-specified input file, parses the equations, calculates solutions, and optionally outputs the results to a file or displays them on the screen.

---

## 🚀 Features

- 📥 Read equations from a structured input file
- 🧠 Detects 2-variable or 3-variable systems
- 📐 Solves using **Cramer's Rule** (determinant-based method)
- 📊 Output options:
  - Terminal (screen)
  - External file
- 🔄 Menu-driven interface
- 🧹 Clean memory and reset between runs
- ❌ Handles errors:
  - Division by zero
  - Invalid formatting
  - File not found

---

## 📂 File Structure

- `main.asm` – Main program logic and UI
- `input_buffer`, `output_buffer` – Data buffers for file operations
- `coeff_array_x`, `coeff_array_y`, `coeff_array_z`, `results_array` – Equation data storage
- Determinant calculations:
  - `determinant_2x2`
  - `determinant_3x3`
- Output formatting and string utilities
- `parse_integer`, `copy_string`, `string_reset` – Integer and string utilities

---

## 📝 Input Format

Input equations should follow a strict format:
2x + 3y = 6 5x - 4y + z = 7

---

- Each line represents a single equation.
- Equations must be fully specified (e.g., missing coefficients default to `1`).
- `z`-term can be omitted for 2-variable systems.
- Systems must be separated by empty lines.

---

## 📤 Output Example

System 1 2X + 3Y = 6 X = 0.00 Y = 2.00

System 2 5X - 4Y + Z = 7 X = 1/2 Y = -3 Z = 1

---
## 🛠 How to Run (on MIPS Simulator)

1. Load `main.asm` into your MIPS simulator (e.g., MARS or SPIM).
2. Assemble and run the program.
3. Follow the terminal menu:
   - Read input file
   - Choose output destination
   - Exit safely

---


