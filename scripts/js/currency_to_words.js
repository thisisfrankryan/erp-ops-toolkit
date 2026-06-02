/**
 * Convert Arabic amount to Chinese uppercase RMB words.
 *
 * Scene:
 * Finance, reimbursement, receipt and payment forms often require both numeric
 * amount and uppercase RMB text. This helper can be bound to an amount input to
 * reduce manual typing and review cost.
 *
 * Example:
 *   convertCurrencyToChineseRMB("12500.35");
 *   // => "壹万贰仟伍佰元叁角伍分"
 */

const RMB_DIGITS = ["零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"];
const RMB_SMALL_UNITS = ["", "拾", "佰", "仟"];
const RMB_GROUP_UNITS = ["", "万", "亿", "兆"];

function addOneToIntegerString(value) {
  let carry = 1;
  const result = [];

  for (let i = value.length - 1; i >= 0; i -= 1) {
    const sum = Number(value[i]) + carry;
    result.unshift(String(sum % 10));
    carry = sum >= 10 ? 1 : 0;
  }

  if (carry) {
    result.unshift("1");
  }

  return result.join("");
}

function normalizeAmountParts(input) {
  const raw = String(input).trim().replace(/[,，\s]/g, "");

  if (!/^-?\d+(\.\d+)?$/.test(raw)) {
    throw new Error("金额格式不正确");
  }

  const negative = raw.startsWith("-");
  const unsigned = negative ? raw.slice(1) : raw;
  let [integerPart, decimalPart = ""] = unsigned.split(".");

  integerPart = integerPart.replace(/^0+(?=\d)/, "") || "0";

  const roundedDigits = (decimalPart + "000").slice(0, 3);
  let cents = Number(roundedDigits.slice(0, 2));

  if (Number(roundedDigits[2]) >= 5) {
    cents += 1;
  }

  if (cents === 100) {
    cents = 0;
    integerPart = addOneToIntegerString(integerPart);
  }

  return { negative, integerPart, cents };
}

function convertFourDigits(group) {
  const padded = group.padStart(4, "0");
  let result = "";
  let zeroPending = false;

  for (let i = 0; i < padded.length; i += 1) {
    const digit = Number(padded[i]);
    const unit = RMB_SMALL_UNITS[padded.length - 1 - i];

    if (digit === 0) {
      if (result) {
        zeroPending = true;
      }
      continue;
    }

    if (zeroPending) {
      result += RMB_DIGITS[0];
      zeroPending = false;
    }

    result += RMB_DIGITS[digit] + unit;
  }

  return result;
}

function convertIntegerPart(integerPart) {
  if (integerPart === "0") {
    return RMB_DIGITS[0];
  }

  const groups = [];
  for (let end = integerPart.length; end > 0; end -= 4) {
    const start = Math.max(0, end - 4);
    groups.unshift(integerPart.slice(start, end));
  }

  let result = "";
  let zeroPending = false;

  groups.forEach((group, index) => {
    const groupValue = Number(group);
    const unitIndex = groups.length - 1 - index;

    if (groupValue === 0) {
      if (result) {
        zeroPending = true;
      }
      return;
    }

    if (zeroPending || (result && group.padStart(4, "0").startsWith("0"))) {
      if (!result.endsWith(RMB_DIGITS[0])) {
        result += RMB_DIGITS[0];
      }
    }

    result += convertFourDigits(group) + RMB_GROUP_UNITS[unitIndex];
    zeroPending = false;
  });

  return result.replace(/零+/g, "零").replace(/零$/g, "");
}

function convertCurrencyToChineseRMB(input) {
  const { negative, integerPart, cents } = normalizeAmountParts(input);
  const prefix = negative ? "负" : "";
  const integerWords = `${convertIntegerPart(integerPart)}元`;

  if (cents === 0) {
    return `${prefix}${integerWords}整`;
  }

  const jiao = Math.floor(cents / 10);
  const fen = cents % 10;
  let decimalWords = "";

  if (jiao > 0) {
    decimalWords += `${RMB_DIGITS[jiao]}角`;
  } else if (fen > 0) {
    decimalWords += "零";
  }

  if (fen > 0) {
    decimalWords += `${RMB_DIGITS[fen]}分`;
  }

  return `${prefix}${integerWords}${decimalWords}`;
}

function bindCurrencyWords(amountSelector, wordsSelector) {
  const amountInput = document.querySelector(amountSelector);
  const wordsInput = document.querySelector(wordsSelector);

  if (!amountInput || !wordsInput) {
    console.warn("[ERP] Amount input or words input not found.");
    return;
  }

  amountInput.addEventListener("input", () => {
    try {
      wordsInput.value = amountInput.value
        ? convertCurrencyToChineseRMB(amountInput.value)
        : "";
    } catch (error) {
      wordsInput.value = "";
      console.warn("[ERP] Invalid amount:", error.message);
    }
  });
}

if (typeof window !== "undefined") {
  window.convertCurrencyToChineseRMB = convertCurrencyToChineseRMB;
  window.bindCurrencyWords = bindCurrencyWords;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    convertCurrencyToChineseRMB,
    bindCurrencyWords
  };
}
