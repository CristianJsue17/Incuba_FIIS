document.addEventListener("DOMContentLoaded", () => {
  // Función para verificar si un elemento está en el viewport
  function isElementInViewport(el) {
    const rect = el.getBoundingClientRect();
    return (
      rect.top <=
        (window.innerHeight || document.documentElement.clientHeight) &&
      rect.bottom >= 0
    );
  }

  // Función para manejar la animación del footer
  function handleFooterAnimation() {
    const footer = document.querySelector(".footer");

    if (isElementInViewport(footer) && !footer.classList.contains("visible")) {
      footer.classList.add("visible");

      // Inicializar las animaciones de los elementos del footer
      const items = document.querySelectorAll(".footer__item");
      items.forEach((item, index) => {
        item.style.opacity = "1";
        item.style.transform = "translateX(0)";
        item.style.transitionDelay = `${0.1 + index * 0.05}s`;
      });
    }
  }

  // Ejecutar la función al cargar la página
  handleFooterAnimation();

  // Ejecutar la función al hacer scroll
  window.addEventListener("scroll", handleFooterAnimation);

  // Manejar el envío del formulario
  const subscribeForm = document.querySelector(".footer__subscribe");
  if (subscribeForm) {
    subscribeForm.addEventListener("submit", (e) => {
      e.preventDefault();
      const input = subscribeForm.querySelector(".footer__input");

      if (input.value.trim() !== "") {
        // Aquí iría la lógica para procesar la suscripción
        alert(`¡Gracias por suscribirte con el email: ${input.value}!`);
        input.value = "";
      } else {
        alert("Por favor, introduce un email válido.");
      }
    });
  }
});
