/**
 * Dependent select reset helper for ERP forms.
 *
 * Scene:
 * Project, department, warehouse and expense item fields often depend on an
 * upstream organization field. When the parent value changes, stale child
 * values must be cleared to avoid submitting inconsistent data.
 */

function clearSelectOptions(selectElement, placeholder = "请选择") {
  if (!selectElement) {
    return;
  }

  selectElement.innerHTML = "";

  const option = document.createElement("option");
  option.value = "";
  option.textContent = placeholder;
  selectElement.appendChild(option);
  selectElement.value = "";
}

function bindDependentSelectReset(parentSelector, childSelectors, options = {}) {
  const parent = document.querySelector(parentSelector);

  if (!parent) {
    console.warn(`[ERP] Parent select not found: ${parentSelector}`);
    return;
  }

  const placeholder = options.placeholder || "请选择";
  const children = childSelectors
    .map((selector) => document.querySelector(selector))
    .filter(Boolean);

  parent.addEventListener("change", () => {
    children.forEach((child) => {
      clearSelectOptions(child, placeholder);
      child.dispatchEvent(new Event("change", { bubbles: true }));
    });

    if (typeof options.afterReset === "function") {
      options.afterReset(parent.value, children);
    }
  });
}

// Example:
// bindDependentSelectReset("#orgId", ["#projectId", "#warehouseId"], {
//   afterReset: (orgId) => loadProjectsByOrg(orgId)
// });

if (typeof window !== "undefined") {
  window.erpDependentSelectReset = {
    clearSelectOptions,
    bindDependentSelectReset
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    clearSelectOptions,
    bindDependentSelectReset
  };
}
