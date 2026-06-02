/**
 * Dynamic form control for ERP pages.
 *
 * Scene:
 * Some ERP forms need conditional fields. For example, when reimbursement type
 * is "科研经费", the research project number must be shown and required; when it
 * is "日常报销", the field should be hidden and cleared.
 */

function getElement(selector) {
  return typeof selector === "string" ? document.querySelector(selector) : selector;
}

function matchExpectedValue(currentValue, expected) {
  if (typeof expected === "function") {
    return expected(currentValue);
  }

  const expectedValues = Array.isArray(expected) ? expected : [expected];
  return expectedValues.some((value) => String(value) === String(currentValue));
}

function setElementVisible(element, visible) {
  if (!element) {
    return;
  }

  element.hidden = !visible;
  element.setAttribute("aria-hidden", visible ? "false" : "true");
}

function setInputRequired(input, required) {
  if (!input) {
    return;
  }

  input.required = required;
  input.setAttribute("aria-required", required ? "true" : "false");
}

function applyDynamicRule(triggerValue, rule) {
  const active = matchExpectedValue(triggerValue, rule.when);

  rule.targets.forEach((target) => {
    const container = getElement(target.containerSelector || target.selector);
    const input = getElement(target.inputSelector || target.selector);
    const visible = target.visibleWhenMatched !== false ? active : !active;

    setElementVisible(container, visible);

    if (target.requiredWhenMatched !== undefined) {
      setInputRequired(input, active ? target.requiredWhenMatched : false);
    }

    if (!visible && target.clearWhenHidden && input && "value" in input) {
      input.value = "";
      input.dispatchEvent(new Event("input", { bubbles: true }));
    }
  });
}

function bindDynamicFormRules(triggerSelector, rules) {
  const trigger = getElement(triggerSelector);

  if (!trigger) {
    console.warn(`[ERP] Dynamic form trigger not found: ${triggerSelector}`);
    return;
  }

  const refresh = () => {
    rules.forEach((rule) => applyDynamicRule(trigger.value, rule));
  };

  trigger.addEventListener("change", refresh);
  trigger.addEventListener("input", refresh);
  refresh();
}

function bindResearchExpenseProjectField(options = {}) {
  const triggerSelector = options.triggerSelector || "#reimbursementType";
  const projectContainerSelector = options.projectContainerSelector || "#researchProjectNoRow";
  const projectInputSelector = options.projectInputSelector || "#researchProjectNo";

  bindDynamicFormRules(triggerSelector, [
    {
      when: ["科研经费", "research", "RESEARCH"],
      targets: [
        {
          containerSelector: projectContainerSelector,
          inputSelector: projectInputSelector,
          requiredWhenMatched: true,
          clearWhenHidden: true
        }
      ]
    }
  ]);
}

// Example:
// bindResearchExpenseProjectField({
//   triggerSelector: "#expenseType",
//   projectContainerSelector: "#researchProjectNoRow",
//   projectInputSelector: "#researchProjectNo"
// });

if (typeof window !== "undefined") {
  window.erpDynamicForm = {
    bindDynamicFormRules,
    bindResearchExpenseProjectField
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    matchExpectedValue,
    bindDynamicFormRules,
    bindResearchExpenseProjectField
  };
}
