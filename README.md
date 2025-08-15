# FormLang++ – Domain-Specific Language & HTML Form Generator

## 📖 Overview

**FormLang++** is a **domain-specific language (DSL)** designed to describe HTML form structures in a clean, human-readable syntax.
It allows developers to define form fields, attributes, validation rules, and metadata using a **structured DSL file**, which is then parsed with **Lex (Flex)** and **Yacc (Bison)** to generate a fully functional, validated HTML form.

This approach **reduces manual HTML form coding effort by over 80%** while improving maintainability and consistency.

---

## 🎯 Project Objective

The goal of this project was to:

* **Design** a DSL for form specification.
* **Parse** the DSL using **Lex/Yacc** with over **20 grammar rules**.
* **Generate HTML forms** from structured input with proper validation.
* **Provide meaningful error handling** for malformed DSL inputs.

---

## 🛠 Key Features

* **DSL-Based Form Specification**

  * Clean, readable syntax for defining form fields, sections, and validations.
  * Support for metadata (e.g., author, version).

* **Supported Field Types**

  | Field Type | Description         | Attributes                       |
  | ---------- | ------------------- | -------------------------------- |
  | `text`     | Single-line input   | `required`, `pattern`, `default` |
  | `textarea` | Multi-line input    | `rows`, `cols`, `default`        |
  | `number`   | Numeric input       | `min`, `max`, `required`         |
  | `email`    | Email input         | `pattern`, `required`            |
  | `date`     | Date picker         | `min`, `max`, `required`         |
  | `checkbox` | Boolean switch      | `default`                        |
  | `dropdown` | Option list         | `required`, `default`, `options` |
  | `radio`    | Single option group | `required`, `options`            |
  | `password` | Masked input        | `required`, `pattern`            |
  | `file`     | File upload         | `accept`, `required`             |

* **Validation Logic**

  * Conditional checks using `validate { if ... }` blocks.
  * Custom error messages.

* **Automatic HTML Generation**

  * Semantic and accessible HTML output.
  * Preserves field order, attributes, and validation rules.

* **Error Handling**

  * Lex/Yacc error recovery for missing tokens, mismatched braces, or unsupported attributes.
  * User-friendly error messages.

---

## 📜 Example DSL Usage

### Input (`registration.form`)

```formlang
form Registration {
  meta author = "SE2062 Team";

  section PersonalDetails {
    field fullName: text required;
    field email: email required;
    field age: number min=18 max=99;
  }

  section Preferences {
    field gender: radio ["Male", "Female", "Other"];
    field newsletter: checkbox default=true;
  }

  validate {
    if age < 18 {
      error "You must be at least 18.";
    }
  }
}
```

### Output (`registration.html`)

```html
<form name="Registration">
  <label>Full Name: <input type="text" name="fullName" required></label><br>
  <label>Email: <input type="email" name="email" required></label><br>
  <label>Age: <input type="number" name="age" min="18" max="99" required></label><br>

  <label>Gender:</label><br>
  <input type="radio" name="gender" value="Male"> Male<br>
  <input type="radio" name="gender" value="Female"> Female<br>
  <input type="radio" name="gender" value="Other"> Other<br>

  <label><input type="checkbox" name="newsletter" checked> Subscribe to newsletter</label><br>
</form>
```

---

## 🏗 Architecture & Tech Stack

### Language & Tools

* **C** – Core programming language for parser implementation.
* **Flex (Lex)** – Tokenization of DSL keywords, identifiers, literals, and symbols.
* **Bison (Yacc)** – Grammar definition and parsing with semantic actions.
* **HTML** – Generated form output.

### Components

* **Lexer (`lexer.l`)**

  * Defines tokens for form keywords, field types, attributes, numbers, and strings.
  * Handles whitespace and comments.

* **Parser (`parser.y`)**

  * Implements grammar rules (20+ EBNF rules).
  * Builds an internal representation of the form.
  * Generates HTML output via `fprintf()`.

* **Grammar Specification (`grammar.pdf`)**

  * EBNF definition for:

    * Form structure (`form`, `section`, `field`)
    * Metadata
    * Field attributes
    * Validation conditions

---

## 📂 Project Structure

```
formlangpp/
│── lexer.l                           # Flex specification for lexical analysis
│── parser.y                          # Yacc grammar for parsing
│── grammar.pdf                       # EBNF grammar specification
│── example.form                      # Sample DSL input
│── output.html                       # Generated HTML output
│── README.md                         # Project documentation
│── Link to Demo Video.txt            # Link to demonstration video
```

---

## ⚙️ Installation & Usage

### Prerequisites

* GCC (C compiler)
* Flex (Lex)
* Bison (Yacc)

### Build & Run

```bash
# Generate C files from Lex and Yacc
flex lexer.l
bison -d parser.y

# Compile
gcc lex.yy.c parser.tab.c -o formlangpp

# Run with sample DSL
./formlangpp example.form
```

The generated `output.html` file will contain the HTML form.

---

## 🛡 Error Handling

* **Syntax Errors** – Detected during parsing with detailed line/column info.
* **Semantic Errors** – Invalid attributes, unknown field types, or missing metadata.
* **Recovery** – Skips invalid sections and continues parsing when possible.

---

## 📊 Performance & Impact

* Reduced manual HTML form coding effort by **>80%**.
* Improved maintainability by separating **form logic** from **HTML markup**.
* Extended grammar for **future support of CSS classes** and **JavaScript validation**.

---

## 🎥 Demo

The project includes a **3-minute video demo** covering:

* Code structure.
* Parsing an example `.form` file.
* Generated HTML output.
* Example of invalid input and error messages.

---

## 📬 Contact

* **Developer:** Pavan Kumarage
* **Email:** pavanvilhan@gmail.com
* **LinkedIn:** linkedin.com/in/pavankumarage

---
