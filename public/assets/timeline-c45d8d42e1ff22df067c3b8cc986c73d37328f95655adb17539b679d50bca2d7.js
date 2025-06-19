document.addEventListener("DOMContentLoaded", () => {
  // Elementos del timeline
  const timelineItems = document.querySelectorAll(".timeline__item");
  const progressFill = document.querySelector(".timeline__progress-fill");

  // Configuración
  const isHorizontal = window.innerWidth >= 768;
  let activeIndex = -1; // Ningún elemento activo inicialmente

  // Inicializar timeline
  function initTimeline() {
    // Añadir eventos a los elementos del timeline
    timelineItems.forEach((item, index) => {
      // Evento de clic
      item.addEventListener("click", () => {
        setActiveItem(index);
      });

      // Evento de hover (solo en dispositivos no táctiles)
      if (window.matchMedia("(hover: hover)").matches) {
        item.addEventListener("mouseenter", () => {
          updateProgress(index);
        });

        item.addEventListener("mouseleave", () => {
          // Si no hay elemento activo, resetear progreso
          if (activeIndex === -1) {
            resetProgress();
          } else {
            updateProgress(activeIndex);
          }
        });
      }
    });

    // Manejar cambios de tamaño de ventana
    window.addEventListener("resize", handleResize);

    // Inicializar progreso
    resetProgress();
  }

  // Establecer elemento activo
  function setActiveItem(index) {
    // Si ya está activo, desactivarlo
    if (activeIndex === index) {
      timelineItems[index].classList.remove("timeline__item--active");
      activeIndex = -1;
      resetProgress();
      return;
    }

    // Desactivar elemento activo anterior
    if (activeIndex !== -1) {
      timelineItems[activeIndex].classList.remove("timeline__item--active");
    }

    // Activar nuevo elemento
    timelineItems[index].classList.add("timeline__item--active");
    activeIndex = index;

    // Actualizar progreso
    updateProgress(index);
  }

  // Actualizar barra de progreso
  function updateProgress(index) {
    const totalItems = timelineItems.length;

    if (isHorizontalLayout()) {
      // Cálculo para layout horizontal
      const progressPercentage = ((index + 1) / totalItems) * 100;
      progressFill.style.width = `${progressPercentage}%`;
    } else {
      // Cálculo para layout vertical
      const progressPercentage = ((index + 1) / totalItems) * 100;
      progressFill.style.height = `${progressPercentage}%`;
    }
  }

  // Resetear progreso
  function resetProgress() {
    if (isHorizontalLayout()) {
      progressFill.style.width = "0%";
    } else {
      progressFill.style.height = "0%";
    }
  }

  // Verificar si el layout es horizontal
  function isHorizontalLayout() {
    return window.innerWidth >= 768;
  }

  // Manejar cambio de tamaño de ventana
  function handleResize() {
    // Verificar si cambió la orientación
    const currentHorizontal = isHorizontalLayout();

    if (currentHorizontal !== isHorizontal) {
      // Resetear progreso si cambió la orientación
      if (activeIndex !== -1) {
        updateProgress(activeIndex);
      } else {
        resetProgress();
      }
    }
  }

  // Añadir animación de entrada
  function addEntryAnimation() {
    timelineItems.forEach((item, index) => {
      // Añadir delay escalonado
      const delay = index * 200;

      setTimeout(() => {
        item.style.opacity = "1";
        item.style.transform = "translateY(0)";
      }, delay);
    });
  }

  // Inicializar timeline
  initTimeline();

  // Añadir animación de entrada después de un breve retraso
  setTimeout(addEntryAnimation, 300);
});
