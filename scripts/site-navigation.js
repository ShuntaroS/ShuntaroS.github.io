// The links are ordinary HTML; only the small-screen disclosure needs JavaScript.
document.addEventListener("DOMContentLoaded", () => {
  const nav = document.querySelector(".site-nav");
  const toggle = document.querySelector(".nav-toggle");
  if (!nav || !toggle) return;
  nav.classList.add("nav-ready");
  const close = () => {
    toggle.setAttribute("aria-expanded", "false");
    nav.classList.remove("nav-open");
  };
  toggle.addEventListener("click", () => {
    const open = toggle.getAttribute("aria-expanded") !== "true";
    toggle.setAttribute("aria-expanded", String(open));
    nav.classList.toggle("nav-open", open);
  });
  nav.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && nav.classList.contains("nav-open")) {
      close();
      toggle.focus();
    }
  });
  nav.addEventListener("focusout", (event) => {
    if (!nav.contains(event.relatedTarget)) close();
  });
  document.addEventListener("click", (event) => {
    if (!nav.contains(event.target)) close();
  });
  window.matchMedia("(min-width: 861px)").addEventListener("change", close);
});
