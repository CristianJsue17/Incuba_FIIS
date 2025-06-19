// ==========================================
// CARRUSEL DE TESTIMONIOS - SIN CONFLICTOS
// Aislado completamente del header y otros scripts
// ==========================================

function initTestimonialsCarousel() {
  
  // Verificar si estamos en la página correcta
  const testimonialsSection = document.querySelector('.testimonials');
  if (!testimonialsSection) {
    console.log('📍 No hay sección de testimonios en esta página');
    return;
  }
  
  // Verificar si ya existe un carrusel (evitar doble inicialización)
  if (window.testimonialsCarouselInstance) {
    console.log('🎠 Carrusel de testimonios ya está activo, destruyendo anterior...');
    window.testimonialsCarouselInstance.destroy();
  }
  
  console.log('🚀 Inicializando carrusel de testimonios...');

  // Variables locales del carrusel (AISLADAS)
  let currentIndex = 0;
  let isAnimating = false;
  let autoplayInterval = null;
  let touchStartX = 0;
  let touchEndX = 0;
  let isHovered = false;
  let isVisible = true;

  // Configuración
  const config = {
    autoplay: true,
    autoplayDelay: 4000, // 4 segundos
    transitionDuration: 800,
    touchThreshold: 50
  };

  // Elementos del DOM
  const track = document.querySelector(".testimonials__track");
  const slides = Array.from(document.querySelectorAll(".testimonial"));
  const nextButton = document.querySelector(".testimonials__nav--next");
  const prevButton = document.querySelector(".testimonials__nav--prev");
  const indicators = Array.from(document.querySelectorAll(".testimonials__indicator"));

  // Verificar que existan los elementos necesarios
  if (!track || slides.length === 0 || !nextButton || !prevButton) {
    console.error('❌ Elementos del carrusel de testimonios no encontrados');
    return;
  }

  // ==========================================
  // FUNCIÓN PRINCIPAL DE INICIALIZACIÓN
  // ==========================================
  function init() {
    try {
      // Configurar estado inicial
      setupInitialState();
      
      // Configurar event listeners ESPECÍFICOS
      setupEventListeners();
      
      // Iniciar autoplay después de un delay
      setTimeout(() => {
        if (config.autoplay) {
          startAutoplay();
          console.log('✅ Autoplay de testimonios iniciado');
        }
      }, 1000); // Delay para evitar conflictos
      
      console.log('✅ Carrusel de testimonios inicializado correctamente');
      
    } catch (error) {
      console.error('❌ Error inicializando carrusel de testimonios:', error);
    }
  }

  // ==========================================
  // CONFIGURAR ESTADO INICIAL
  // ==========================================
  function setupInitialState() {
    slides.forEach((slide, index) => {
      slide.classList.remove('testimonial--active', 'testimonial--prev', 'testimonial--next');
      if (index === 0) {
        slide.classList.add('testimonial--active');
      }
    });

    updateIndicators();
    
    console.log(`📊 Estado inicial: ${slides.length} testimonios, slide activo: ${currentIndex + 1}`);
  }

  // ==========================================
  // EVENT LISTENERS ESPECÍFICOS Y AISLADOS
  // ==========================================
  function setupEventListeners() {
    // Botones de navegación - CON NAMESPACE ESPECÍFICO
    const handleNext = (e) => {
      e.stopPropagation();
      if (!isAnimating) {
        goToSlide(currentIndex + 1, 'next');
      }
    };

    const handlePrev = (e) => {
      e.stopPropagation();
      if (!isAnimating) {
        goToSlide(currentIndex - 1, 'prev');
      }
    };

    nextButton.addEventListener("click", handleNext);
    prevButton.addEventListener("click", handlePrev);

    // Indicadores
    indicators.forEach((indicator) => {
      const handleIndicatorClick = (e) => {
        e.stopPropagation();
        if (!isAnimating) {
          const index = parseInt(indicator.dataset.index);
          if (!isNaN(index) && index !== currentIndex) {
            const direction = index > currentIndex ? 'next' : 'prev';
            goToSlide(index, direction);
          }
        }
      };
      indicator.addEventListener("click", handleIndicatorClick);
    });

    // Eventos touch para móviles - SOLO EN EL TRACK
    setupTouchEvents();

    // Hover events - SOLO EN LA SECCIÓN DE TESTIMONIOS
    const handleMouseEnter = () => {
      isHovered = true;
      console.log('🎯 Hover en testimonios - pausando autoplay');
    };

    const handleMouseLeave = () => {
      isHovered = false;
      console.log('🎯 Hover fuera de testimonios - reanudando autoplay');
    };

    testimonialsSection.addEventListener('mouseenter', handleMouseEnter);
    testimonialsSection.addEventListener('mouseleave', handleMouseLeave);

    // Intersection Observer para detectar visibilidad - MÁS PRECISO
    const observerOptions = {
      root: null,
      rootMargin: '0px',
      threshold: 0.3 // 30% visible
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        isVisible = entry.isIntersecting;
        console.log(`👁️ Testimonios ${isVisible ? 'visible' : 'oculto'}`);
      });
    }, observerOptions);

    observer.observe(testimonialsSection);

    // Guardar referencias para cleanup
    window.testimonialsEventCleanup = {
      nextButton,
      prevButton,
      handleNext,
      handlePrev,
      testimonialsSection,
      handleMouseEnter,
      handleMouseLeave,
      observer
    };

    console.log('🎮 Event listeners de testimonios configurados (aislados)');
  }

  // ==========================================
  // NAVEGACIÓN PRINCIPAL DEL CARRUSEL
  // ==========================================
  function goToSlide(targetIndex, direction = 'next') {
    if (isAnimating) return;

    // NAVEGACIÓN CIRCULAR
    let newIndex = targetIndex;
    if (targetIndex < 0) {
      newIndex = slides.length - 1;
    } else if (targetIndex >= slides.length) {
      newIndex = 0;
    }

    if (newIndex === currentIndex) return;

    isAnimating = true;

    // Obtener slides actual y objetivo
    const currentSlide = slides[currentIndex];
    const targetSlide = slides[newIndex];

    // ANIMACIONES FLUIDAS
    if (direction === 'next') {
      currentSlide.style.animation = "testimonialSlideOutLeft 0.8s forwards";
      targetSlide.style.animation = "testimonialSlideInRight 0.8s forwards";
    } else {
      currentSlide.style.animation = "testimonialSlideOutRight 0.8s forwards";
      targetSlide.style.animation = "testimonialSlideInLeft 0.8s forwards";
    }

    // Actualizar después de la animación
    setTimeout(() => {
      currentSlide.classList.remove("testimonial--active");
      currentSlide.style.animation = "";

      targetSlide.classList.add("testimonial--active");
      targetSlide.style.animation = "";

      currentIndex = newIndex;
      updateIndicators();
      isAnimating = false;

      console.log(`🎠 Navegando a testimonio ${currentIndex + 1}/${slides.length}`);

    }, config.transitionDuration);
  }

  // ==========================================
  // AUTOPLAY ROBUSTO Y AISLADO
  // ==========================================
  function startAutoplay() {
    stopAutoplay(); // Limpiar cualquier intervalo previo
    
    if (!config.autoplay) return;
    
    autoplayInterval = setInterval(() => {
      // VERIFICACIONES MÚLTIPLES ANTES DE AVANZAR
      const shouldAdvance = !isAnimating && 
                           !isHovered && 
                           isVisible && 
                           !document.hidden &&
                           document.querySelector('.testimonials'); // Asegurar que la sección existe

      if (shouldAdvance) {
        goToSlide(currentIndex + 1, 'next');
      } else {
        console.log('⏸️ Autoplay pausado por condiciones:', {
          isAnimating,
          isHovered,
          isVisible,
          documentHidden: document.hidden
        });
      }
    }, config.autoplayDelay);
    
    console.log('▶️ Autoplay iniciado con intervalo de', config.autoplayDelay, 'ms');
  }

  function stopAutoplay() {
    if (autoplayInterval) {
      clearInterval(autoplayInterval);
      autoplayInterval = null;
      console.log('⏸️ Autoplay detenido');
    }
  }

  // ==========================================
  // ACTUALIZAR INDICADORES
  // ==========================================
  function updateIndicators() {
    indicators.forEach((indicator, index) => {
      if (index === currentIndex) {
        indicator.classList.add("testimonials__indicator--active");
      } else {
        indicator.classList.remove("testimonials__indicator--active");
      }
    });
  }

  // ==========================================
  // EVENTOS TOUCH AISLADOS
  // ==========================================
  function setupTouchEvents() {
    const handleTouchStart = (e) => {
      touchStartX = e.changedTouches[0].screenX;
      isHovered = true; // Pausar autoplay durante touch
    };

    const handleTouchMove = (e) => {
      const touchCurrentX = e.changedTouches[0].screenX;
      const deltaX = Math.abs(touchCurrentX - touchStartX);
      
      if (deltaX > 10) {
        e.preventDefault();
      }
    };

    const handleTouchEnd = (e) => {
      touchEndX = e.changedTouches[0].screenX;
      const deltaX = touchStartX - touchEndX;
      
      if (Math.abs(deltaX) > config.touchThreshold) {
        if (deltaX > 0) {
          goToSlide(currentIndex + 1, 'next');
        } else {
          goToSlide(currentIndex - 1, 'prev');
        }
      }
      
      // Reanudar autoplay después de 3 segundos
      setTimeout(() => {
        isHovered = false;
      }, 3000);
    };

    track.addEventListener("touchstart", handleTouchStart, { passive: true });
    track.addEventListener("touchmove", handleTouchMove, { passive: false });
    track.addEventListener("touchend", handleTouchEnd, { passive: true });
  }

  // ==========================================
  // FUNCIÓN DE DESTRUCCIÓN COMPLETA
  // ==========================================
  function destroy() {
    console.log('🧹 Destruyendo carrusel de testimonios...');
    
    // Detener autoplay
    stopAutoplay();
    
    // Limpiar event listeners si existen
    if (window.testimonialsEventCleanup) {
      const cleanup = window.testimonialsEventCleanup;
      
      if (cleanup.nextButton && cleanup.handleNext) {
        cleanup.nextButton.removeEventListener("click", cleanup.handleNext);
      }
      
      if (cleanup.prevButton && cleanup.handlePrev) {
        cleanup.prevButton.removeEventListener("click", cleanup.handlePrev);
      }
      
      if (cleanup.testimonialsSection) {
        cleanup.testimonialsSection.removeEventListener('mouseenter', cleanup.handleMouseEnter);
        cleanup.testimonialsSection.removeEventListener('mouseleave', cleanup.handleMouseLeave);
      }
      
      if (cleanup.observer) {
        cleanup.observer.disconnect();
      }
      
      window.testimonialsEventCleanup = null;
    }
    
    // Limpiar referencia
    window.testimonialsCarouselInstance = null;
    
    console.log('✅ Carrusel de testimonios destruido completamente');
  }

  // ==========================================
  // CREAR INSTANCIA PÚBLICA
  // ==========================================
  const publicAPI = {
    goToSlide: (index) => goToSlide(index),
    next: () => goToSlide(currentIndex + 1, 'next'),
    prev: () => goToSlide(currentIndex - 1, 'prev'),
    startAutoplay: startAutoplay,
    stopAutoplay: stopAutoplay,
    destroy: destroy,
    getCurrentIndex: () => currentIndex,
    getTotalSlides: () => slides.length,
    isPlaying: () => autoplayInterval !== null
  };

  // ==========================================
  // INICIALIZAR Y GUARDAR INSTANCIA
  // ==========================================
  init();
  window.testimonialsCarouselInstance = publicAPI;
  
  return publicAPI;
}

// ==========================================
// INICIALIZACIÓN ROBUSTA CON REINTENTOS
// ==========================================
function initTestimonialsWithRetry(retries = 3, delay = 300) {
  if (retries <= 0) {
    console.warn('⚠️ No se pudo inicializar testimonios después de varios intentos');
    return;
  }
  
  try {
    const testimonialsSection = document.querySelector('.testimonials');
    if (testimonialsSection) {
      initTestimonialsCarousel();
    } else {
      console.log(`🔄 Testimonios no encontrado, reintentando... (${retries} intentos restantes)`);
      setTimeout(() => initTestimonialsWithRetry(retries - 1, delay), delay);
    }
  } catch (error) {
    console.warn(`⚠️ Error al inicializar testimonios, reintentando... (${retries} intentos restantes)`, error);
    setTimeout(() => initTestimonialsWithRetry(retries - 1, delay), delay);
  }
}

// ==========================================
// EVENTOS DE INICIALIZACIÓN SEPARADOS
// ==========================================
document.addEventListener("DOMContentLoaded", () => {
  console.log('📄 DOMContentLoaded - iniciando testimonios...');
  setTimeout(() => initTestimonialsWithRetry(), 500);
});

document.addEventListener("turbo:load", () => {
  console.log('🚂 Turbo:load - iniciando testimonios...');
  setTimeout(() => initTestimonialsWithRetry(), 800);
});

document.addEventListener("turbo:render", () => {
  console.log('🎨 Turbo:render - iniciando testimonios...');
  setTimeout(() => initTestimonialsWithRetry(), 400);
});

// ==========================================
// LIMPIEZA ANTES DE NAVEGACIÓN
// ==========================================
document.addEventListener('turbo:before-visit', () => {
  if (window.testimonialsCarouselInstance) {
    window.testimonialsCarouselInstance.destroy();
    console.log('🧹 Testimonios limpiado para navegación Turbo');
  }
});

// ==========================================
// INICIALIZACIÓN MANUAL DE EMERGENCIA
// ==========================================
setTimeout(() => {
  if (!window.testimonialsCarouselInstance) {
    const testimonialsSection = document.querySelector('.testimonials');
    if (testimonialsSection) {
      console.log('🚨 Inicialización de emergencia activada');
      initTestimonialsWithRetry();
    }
  }
}, 3000);

// Función global para debugging
window.debugTestimonials = () => {
  if (window.testimonialsCarouselInstance) {
    console.log('🐛 Estado del carrusel:', {
      current: window.testimonialsCarouselInstance.getCurrentIndex(),
      total: window.testimonialsCarouselInstance.getTotalSlides(),
      playing: window.testimonialsCarouselInstance.isPlaying()
    });
  } else {
    console.log('🐛 No hay instancia de carrusel activa');
  }
};

console.log("🎠 Sistema de carrusel de testimonios cargado - VERSIÓN AISLADA SIN CONFLICTOS");