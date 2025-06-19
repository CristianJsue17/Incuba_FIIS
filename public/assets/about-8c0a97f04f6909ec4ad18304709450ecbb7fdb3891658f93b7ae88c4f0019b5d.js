document.addEventListener("DOMContentLoaded", () => {
  // Mostrar elementos con animación solo al cargar la página
  const elements = document.querySelectorAll(".about__header, .about__section");

  elements.forEach((element) => {
    element.classList.add("animate");
  });

  // Efecto hover en las imágenes
  const imageWrappers = document.querySelectorAll(".about__image-wrapper");

  imageWrappers.forEach((wrapper) => {
    const image = wrapper.querySelector(".about__image");

    wrapper.addEventListener("mouseenter", () => {
      image.style.transform = "scale(1.05)";
    });

    wrapper.addEventListener("mouseleave", () => {
      image.style.transform = "scale(1)";
    });
  });
});
