/**
 * Clean pasted data from Excel, web pages or external documents.
 *
 * Scene:
 * ERP users often paste tax IDs, bank accounts, invoice titles or order numbers
 * from Excel and web pages. Hidden spaces, line breaks and full-width
 * punctuation may cause field length errors or format validation failures.
 */

const PUNCTUATION_MAP = {
  "，": ",",
  "。": ".",
  "：": ":",
  "；": ";",
  "（": "(",
  "）": ")",
  "【": "[",
  "】": "]",
  "“": "\"",
  "”": "\"",
  "‘": "'",
  "’": "'",
  "、": ",",
  "－": "-",
  "—": "-"
};

function toHalfWidth(text) {
  return String(text).replace(/[\uFF01-\uFF5E]/g, (char) =>
    String.fromCharCode(char.charCodeAt(0) - 0xfee0)
  ).replace(/\u3000/g, " ");
}

function normalizePunctuation(text) {
  return String(text).replace(/[，。：；（）【】“”‘’、－—]/g, (char) =>
    PUNCTUATION_MAP[char] || char
  );
}

function cleanPastedText(input, options = {}) {
  const removeAllSpaces = options.removeAllSpaces !== false;
  const uppercase = options.uppercase === true;
  const keepLineBreak = options.keepLineBreak === true;

  let value = toHalfWidth(input)
    .replace(/[\u200B-\u200D\uFEFF]/g, "")
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n");

  value = normalizePunctuation(value);

  if (keepLineBreak) {
    value = removeAllSpaces ? value.replace(/[ \t]+/g, "") : value.replace(/[ \t]+/g, " ");
  } else {
    value = removeAllSpaces ? value.replace(/\s+/g, "") : value.replace(/\s+/g, " ");
  }

  value = value.trim();

  return uppercase ? value.toUpperCase() : value;
}

function cleanTaxId(input) {
  return cleanPastedText(input, { uppercase: true }).replace(/[^0-9A-Z]/g, "");
}

function cleanBankAccount(input) {
  return cleanPastedText(input).replace(/[^\d]/g, "");
}

function cleanInvoiceTitle(input) {
  return cleanPastedText(input);
}

function bindPasteCleaner(selector, cleaner = cleanPastedText) {
  const input = document.querySelector(selector);

  if (!input) {
    console.warn(`[ERP] Paste target not found: ${selector}`);
    return;
  }

  input.addEventListener("paste", (event) => {
    event.preventDefault();
    const clipboard = event.clipboardData || window.clipboardData;
    const pastedText = clipboard ? clipboard.getData("text") : "";
    input.value = cleaner(pastedText);
    input.dispatchEvent(new Event("input", { bubbles: true }));
  });
}

if (typeof window !== "undefined") {
  window.erpPasteCleaner = {
    cleanPastedText,
    cleanTaxId,
    cleanBankAccount,
    cleanInvoiceTitle,
    bindPasteCleaner
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    cleanPastedText,
    cleanTaxId,
    cleanBankAccount,
    cleanInvoiceTitle,
    bindPasteCleaner
  };
}
