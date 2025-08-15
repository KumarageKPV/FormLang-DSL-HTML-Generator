%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// Output HTML file
FILE *out;

// Lexer and error function declarations
void yyerror(const char *s);
int yylex(void);
extern int yylineno;

// Collect dropdown/radio options in this array
char options[100][256];
int option_count = 0;

// Enum to make field types easier to manage
enum FieldTypes {
    TYPE_TEXT = 256,
    TYPE_TEXTAREA,
    TYPE_NUMBER,
    TYPE_EMAIL,
    TYPE_DATE,
    TYPE_PASSWORD,
    TYPE_FILE,
    TYPE_CHECKBOX,
    TYPE_DROPDOWN,
    TYPE_RADIO
};

// Structure for optional field attributes
typedef struct {
    int is_required;
    char* default_value;
    char* min;
    char* max;
    char* pattern;
    char* accept;
    int rows;
    int cols;
} Attributes;

Attributes current_attrs; // This holds the current field's attributes

// Helper function to convert identifiers like "user_name" or "firstName" into pretty labels
char* capitalize_label(const char* label) {
    char temp[256];
    int j = 0;
    char prev_char = '\0';
    for (int i = 0; label[i] != '\0'; i++) {
        char c = label[i];
        if (isupper(c) && prev_char && islower(prev_char)) {
            temp[j++] = ' ';
        }
        temp[j++] = (c == '_') ? ' ' : c;
        prev_char = c;
    }
    temp[j] = '\0';

    // Capitalize each word
    char result[256];
    int k = 0, capitalize = 1;
    for (int i = 0; temp[i]; i++) {
        if (temp[i] == ' ') {
            result[k++] = ' ';
            capitalize = 1;
        } else if (capitalize) {
            result[k++] = toupper(temp[i]);
            capitalize = 0;
        } else {
            result[k++] = tolower(temp[i]);
        }
    }
    result[k] = '\0';
    return strdup(result);
}

// Reset attribute values before parsing a new field
void reset_attrs() {
    current_attrs.is_required = 0;
    current_attrs.default_value = NULL;
    current_attrs.min = NULL;
    current_attrs.max = NULL;
    current_attrs.pattern = NULL;
    current_attrs.accept = NULL;
    current_attrs.rows = 0;
    current_attrs.cols = 0;
}
%}

%union {
    int num;
    char *str;
}

%token <str> IDENTIFIER STRING BOOL
%token <num> NUMBER
%token FORM META SECTION FIELD VALIDATE IF ERROR
%token REQUIRED DEFAULT MIN MAX PATTERN ACCEPT ROWS COLS OPTIONS
%token LBRACE RBRACE LBRACK RBRACK COLON SEMI EQ COMMA LT GT

%type <num> field_type
%type <str> attr_value

%%

form: FORM IDENTIFIER LBRACE {
    // HTML header and styles start here
    fprintf(out, "<!DOCTYPE html>\n<html>\n<head>\n<title>%s</title>\n<style>\n", $2);
    fprintf(out, "body { font-family: 'Segoe UI', Arial, sans-serif; max-width: 900px; margin: 40px auto; padding: 20px; background: #f5f5f5; }\n");
    fprintf(out, "h1 { text-align: center; color: #333; margin-bottom: 30px; font-size: 28px; }\n");
    fprintf(out, "form { background: #ffffff; padding: 30px; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }\n");
    fprintf(out, "fieldset { margin-bottom: 25px; border: 2px solid #e0e0e0; border-radius: 8px; padding: 20px; background: #fafafa; }\n");
    fprintf(out, "legend { font-weight: 600; font-size: 18px; color: #444; padding: 0 10px; }\n");
    fprintf(out, "label { display: inline-block; width: 180px; margin-bottom: 15px; font-weight: 500; color: #555; font-size: 16px; }\n");
    fprintf(out, "input, textarea, select { width: calc(100%% - 200px); padding: 10px; margin-bottom: 15px; border: 1px solid #ddd; border-radius: 5px; font-size: 15px; color: #333; }\n");
    fprintf(out, "input[type='radio'], input[type='checkbox'] { width: auto; margin-right: 10px; vertical-align: middle; position: relative; top: 6px; }\n");
    fprintf(out, ".required::after { content: '*'; color: #e63946; margin-left: 5px; font-size: 16px; }\n");
    fprintf(out, "button { display: block; width: 200px; margin: 30px auto 0; background: #1d3557; color: white; padding: 12px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; transition: background 0.3s; }\n");
    fprintf(out, "button:hover { background: #2a4b7c; }\n");
    fprintf(out, "div.field-container { margin-bottom: 15px; display: flex; align-items: center; }\n");
    fprintf(out, "</style>\n</head>\n<body>\n");

    // Use a human readable version of the form name
    char* form_title = capitalize_label($2);
    fprintf(out, "<h1>%s Form</h1>\n<form name='%s'>\n", form_title, $2);
    free(form_title);
}
meta_block_opt sections validate_opt RBRACE {
    // Wrap up the form
    fprintf(out, "<button type='submit'>Submit</button>\n</form>\n</body>\n</html>\n");
    free($2);
};

meta_block_opt:
    /* optional metadata section */
    | meta_block
;

meta_block:
    meta_block meta_entry
    | meta_entry
;

meta_entry:
    META IDENTIFIER EQ STRING SEMI {
        fprintf(out, "<!-- Meta: %s = %s -->\n", $2, $4);
        free($2); free($4);
    }
;

sections:
    sections section
    | section
;

section: SECTION IDENTIFIER LBRACE {
    // Start a fieldset section with a heading
    char* section_title = capitalize_label($2);
    fprintf(out, "<fieldset>\n<legend>%s</legend>\n", section_title);
    free(section_title);
} field_list RBRACE {
    fprintf(out, "</fieldset>\n<!-- End of section: %s -->\n", $2);
    free($2);
};

field_list:
    field_list field
    | field
;

field:
    FIELD IDENTIFIER COLON field_type attributes_opt SEMI {
        char* field_label = capitalize_label($2);
        fprintf(out, "<div class='field-container'>\n");

        const char *type_str =
            $4 == TYPE_TEXT ? "text" :
            $4 == TYPE_NUMBER ? "number" :
            $4 == TYPE_EMAIL ? "email" :
            $4 == TYPE_DATE ? "date" :
            $4 == TYPE_PASSWORD ? "password" :
            $4 == TYPE_FILE ? "file" : "text";

        // Handle all types of fields from textarea to checkbox to radio
        if ($4 == TYPE_TEXTAREA) {
            // Multiline text input
            fprintf(out, "<label for='%s'%s>%s:</label>\n", $2, current_attrs.is_required ? " class='required'" : "", field_label);
            fprintf(out, "<textarea id='%s' name='%s'", $2, $2);
            if (current_attrs.rows > 0) fprintf(out, " rows='%d'", current_attrs.rows);
            if (current_attrs.cols > 0) fprintf(out, " cols='%d'", current_attrs.cols);
            if (current_attrs.is_required) fprintf(out, " required");
            fprintf(out, ">");
            if (current_attrs.default_value) fprintf(out, "%s", current_attrs.default_value);
            fprintf(out, "</textarea>\n");
        } else if ($4 == TYPE_CHECKBOX) {
            // Single checkbox
            fprintf(out, "<label for='%s'%s>%s:</label>\n", $2, current_attrs.is_required ? " class='required'" : "", field_label);
            fprintf(out, "<label><input type='checkbox' id='%s' name='%s'", $2, $2);
            if (current_attrs.default_value && strcmp(current_attrs.default_value, "true") == 0) fprintf(out, " checked");
            if (current_attrs.is_required) fprintf(out, " required");
        } else if ($4 == TYPE_RADIO) {
            // Multiple choice (radio buttons)
            fprintf(out, "<label>%s:</label>\n", field_label);
            fprintf(out, "<div class='radio-group'>\n");
            for (int i = 0; i < option_count; i++) {
                fprintf(out, "<label><input type='radio' name='%s' value='%s'", $2, options[i]);
                if (current_attrs.default_value && strcmp(current_attrs.default_value, options[i]) == 0)
                    fprintf(out, " checked");
                fprintf(out, "> %s</label><br>\n", options[i]);
            }
            fprintf(out, "</div>\n");
        } else if ($4 == TYPE_DROPDOWN) {
            // Dropdown field
            fprintf(out, "<label for='%s'%s>%s:</label>\n", $2, current_attrs.is_required ? " class='required'" : "", field_label);
            fprintf(out, "<select id='%s' name='%s'%s>\n", $2, $2, current_attrs.is_required ? " required" : "");
            for (int i = 0; i < option_count; i++) {
                fprintf(out, "<option value='%s'%s>%s</option>\n", options[i],
                        (current_attrs.default_value && strcmp(current_attrs.default_value, options[i]) == 0) ? " selected" : "",
                        options[i]);
            }
            fprintf(out, "</select>\n");
        } else {
            // Any basic input type
            fprintf(out, "<label for='%s'%s>%s:</label>\n", $2, current_attrs.is_required ? " class='required'" : "", field_label);
            fprintf(out, "<input id='%s' type='%s' name='%s'", $2, type_str, $2);
            if (current_attrs.default_value) fprintf(out, " value='%s'", current_attrs.default_value);
            if (current_attrs.is_required) fprintf(out, " required");
            if (current_attrs.min && ($4 == TYPE_NUMBER || $4 == TYPE_DATE)) fprintf(out, " min='%s'", current_attrs.min);
            if (current_attrs.max && ($4 == TYPE_NUMBER || $4 == TYPE_DATE)) fprintf(out, " max='%s'", current_attrs.max);
            if (current_attrs.pattern) fprintf(out, " pattern='%s'", current_attrs.pattern);
            if (current_attrs.accept && $4 == TYPE_FILE) fprintf(out, " accept='%s'", current_attrs.accept);
            fprintf(out, ">\n");
        }

        fprintf(out, "</div>\n");

        // Clean up after each field
        if (current_attrs.default_value) free(current_attrs.default_value);
        if (current_attrs.min) free(current_attrs.min);
        if (current_attrs.max) free(current_attrs.max);
        if (current_attrs.pattern) free(current_attrs.pattern);
        if (current_attrs.accept) free(current_attrs.accept);
        reset_attrs();

        // Clear options
        option_count = 0;
        for (int i = 0; i < 100; i++) options[i][0] = '\0';

        free(field_label);
        free($2);
    }
;

// Field type handler
field_type:
    IDENTIFIER {
        if (strcmp($1, "text") == 0) $$ = TYPE_TEXT;
        else if (strcmp($1, "textarea") == 0) $$ = TYPE_TEXTAREA;
        else if (strcmp($1, "number") == 0) $$ = TYPE_NUMBER;
        else if (strcmp($1, "email") == 0) $$ = TYPE_EMAIL;
        else if (strcmp($1, "date") == 0) $$ = TYPE_DATE;
        else if (strcmp($1, "password") == 0) $$ = TYPE_PASSWORD;
        else if (strcmp($1, "file") == 0) $$ = TYPE_FILE;
        else if (strcmp($1, "checkbox") == 0) $$ = TYPE_CHECKBOX;
        else if (strcmp($1, "dropdown") == 0) $$ = TYPE_DROPDOWN;
        else if (strcmp($1, "radio") == 0) $$ = TYPE_RADIO;
        else {
            fprintf(stderr, "Error: Unknown field type '%s' at line %d\n", $1, yylineno);
            YYERROR;
        }
        free($1);
    }
;

attributes_opt:
    /* optional attributes */ { reset_attrs(); }
    | attributes
;

attributes:
    attributes attribute
    | attribute
;

attribute:
    REQUIRED { current_attrs.is_required = 1; }
    | DEFAULT EQ attr_value { current_attrs.default_value = $3; }
    | MIN EQ attr_value { current_attrs.min = $3; }
    | MAX EQ attr_value { current_attrs.max = $3; }
    | PATTERN EQ STRING { current_attrs.pattern = $3; }
    | ACCEPT EQ STRING { current_attrs.accept = $3; }
    | ROWS EQ NUMBER { current_attrs.rows = $3; }
    | COLS EQ NUMBER { current_attrs.cols = $3; }
    | OPTIONS EQ LBRACK option_list RBRACK
;

attr_value:
    STRING { $$ = $1; }
    | BOOL { $$ = $1; }
    | NUMBER {
        // Convert number to string for HTML
        $$ = (char *)malloc(16);
        snprintf($$, 16, "%d", $1);
    }
;

option_list:
    option_list COMMA STRING {
        strcpy(options[option_count++], $3);
        free($3);
    }
    | STRING {
        strcpy(options[option_count++], $1);
        free($1);
    }
;

validate_opt:
    /* optional validation section */
    | VALIDATE LBRACE validations RBRACE
;

validations:
    validations validation
    | validation
;

validation:
    IF IDENTIFIER LT NUMBER LBRACE ERROR STRING SEMI RBRACE {
        fprintf(out, "<!-- Validation: if %s < %d, error: %s -->\n", $2, $4, $7);
        free($2); free($7);
    }
;

%%

// If something goes wrong during parsing
void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
}

// Entry point
int main(void) {
    out = fopen("output.html", "w");
    if (!out) {
        fprintf(stderr, "Error opening output.html\n");
        return 1;
    }

    if (yyparse() == 0) {
        printf("Valid form parsed.\n");
    } else {
        printf("Form parsing failed.\n");
    }

    fclose(out);
    return 0;
}