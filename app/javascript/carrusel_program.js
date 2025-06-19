// CARRUSEL DE PROGRAMAS - VERSIÓN CORREGIDA CON LÍMITE DE 3 SLIDES
function initProgramsCarousel() {
  
  // Verificar si estamos en la página con programas
  const programsGrid = document.querySelector('.programs-grid');
  if (!programsGrid) {
    console.log('📍 No hay grid de programas en esta página');
    return;
  }
  
  // Verificar si ya existe un carrusel (evitar doble inicialización)
  if (document.querySelector('.programs-carousel')) {
    console.log('🎠 Carrusel ya existe, saliendo...');
    return;
  }
  
  console.log('🚀 Inicializando carrusel de programas...');

  // Variables globales del carrusel
  let currentSlide = 0;
  let totalSlides = 0;
  let maxSlides = 3; // LÍMITE FIJO DE 3 SLIDES
  let isTransitioning = false;
  let autoplayInterval = null;
  let carouselTrack = null;
  let slides = [];
  let indicators = [];

  // Configuración
  const config = {
    autoplay: false,
    autoplayDelay: 5000,
    transitionDuration: 800,
    cardsPerSlide: {
      mobile: 1,
      tablet: 2,
      desktop: 3
    }
  };

  // ==========================================
  // FUNCIÓN PRINCIPAL DE INICIALIZACIÓN
  // ==========================================
  function init() {
    try {
      // Obtener las tarjetas existentes (máximo 9)
      const existingCards = Array.from(programsGrid.querySelectorAll('article.program-card'));
      
      if (existingCards.length === 0) {
        console.log('❌ No hay tarjetas de programa para mostrar');
        return;
      }
      
      console.log(`📊 Encontradas ${existingCards.length} tarjetas de programa de la BD`);
      
      // Añadir data-type a las tarjetas existentes basado en el badge
      addDataTypeToCards(existingCards);
      
      createCarouselStructure(existingCards);
      setupEventListeners();
      updateCarousel();
      
      if (config.autoplay) {
        startAutoplay();
      }
      
      console.log('✅ Carrusel de programas inicializado correctamente');
      
    } catch (error) {
      console.error('❌ Error inicializando carrusel:', error);
    }
  }

  // ==========================================
  // AÑADIR DATA-TYPE A TARJETAS EXISTENTES
  // ==========================================
  function addDataTypeToCards(cards) {
    cards.forEach(card => {
      // Buscar el badge de tipo en la tarjeta
      const typeBadge = card.querySelector('[class*="program-type-"]');
      if (typeBadge) {
        // Extraer el tipo del nombre de la clase
        const typeClasses = typeBadge.className.split(' ');
        const typeClass = typeClasses.find(cls => cls.startsWith('program-type-'));
        if (typeClass) {
          const type = typeClass.replace('program-type-', '');
          card.setAttribute('data-type', type);
          console.log(`🏷️ Asignado data-type="${type}" a tarjeta`);
        }
      }
    });
  }

  // ==========================================
  // CREAR ESTRUCTURA DEL CARRUSEL
  // ==========================================
  function createCarouselStructure(programCards) {
    // Determinar cuántas tarjetas por slide según el viewport
    const cardsPerSlide = getCardsPerSlide();
    
    // CALCULAR SLIDES CON LÍMITE MÁXIMO DE 3
    const calculatedSlides = Math.ceil(programCards.length / cardsPerSlide);
    totalSlides = Math.min(calculatedSlides, maxSlides); // MÁXIMO 3 SLIDES
    
    console.log(`📐 Calculado: ${calculatedSlides} slides, limitado a: ${totalSlides} slides máximo`);

    // Crear estructura del carrusel
    const carouselHTML = `
      <div class="programs-carousel">
        <div class="programs-carousel-wrapper">
          <div class="programs-carousel-track">
            ${createSlides(programCards, cardsPerSlide)}
          </div>
        </div>
      </div>
      <div class="carousel-controls">
        <button class="carousel-nav carousel-prev" aria-label="Anterior">
          <i class="fas fa-chevron-left"></i>
        </button>
        <div class="carousel-indicators">
          ${createIndicators()}
        </div>
        <div class="carousel-counter">
          <span class="current-slide">1</span> / <span class="total-slides">${totalSlides}</span>
        </div>
        <button class="carousel-nav carousel-next" aria-label="Siguiente">
          <i class="fas fa-chevron-right"></i>
        </button>
      </div>
    `;

    // Reemplazar solo el programs-grid con el carrusel
    programsGrid.outerHTML = carouselHTML;

    // Actualizar referencias
    carouselTrack = document.querySelector('.programs-carousel-track');
    slides = Array.from(document.querySelectorAll('.programs-carousel-slide'));
    indicators = Array.from(document.querySelectorAll('.carousel-indicator'));

    console.log(`📊 Carrusel creado: ${totalSlides} slides, ${cardsPerSlide} tarjetas por slide`);
  }

  // ==========================================
  // CREAR SLIDES CON LÍMITE
  // ==========================================
  function createSlides(cards, cardsPerSlide) {
    let slidesHTML = '';
    let slideCount = 0;
    
    for (let i = 0; i < cards.length && slideCount < maxSlides; i += cardsPerSlide) {
      const slideCards = cards.slice(i, i + cardsPerSlide);
      slidesHTML += `
        <div class="programs-carousel-slide">
          ${slideCards.map(card => card.outerHTML).join('')}
        </div>
      `;
      slideCount++;
    }
    
    return slidesHTML;
  }

  // ==========================================
  // CREAR INDICADORES (MÁXIMO 3)
  // ==========================================
  function createIndicators() {
    let indicatorsHTML = '';
    
    for (let i = 0; i < totalSlides; i++) {
      indicatorsHTML += `
        <button class="carousel-indicator ${i === 0 ? 'active' : ''}" 
                data-slide="${i}" 
                aria-label="Ir al slide ${i + 1}">
        </button>
      `;
    }
    
    return indicatorsHTML;
  }

  // ==========================================
  // DETERMINAR TARJETAS POR SLIDE
  // ==========================================
  function getCardsPerSlide() {
    const width = window.innerWidth;
    
    if (width < 768) {
      return config.cardsPerSlide.mobile;
    } else if (width < 1200) {
      return config.cardsPerSlide.tablet;
    } else {
      return config.cardsPerSlide.desktop;
    }
  }

  // ==========================================
  // CONFIGURAR EVENT LISTENERS
  // ==========================================
  function setupEventListeners() {
    // Botones de navegación
    const prevBtn = document.querySelector('.carousel-prev');
    const nextBtn = document.querySelector('.carousel-next');
    
    if (prevBtn) {
      prevBtn.addEventListener('click', () => {
        if (!isTransitioning) {
          goToSlide(currentSlide - 1);
        }
      });
    }
    
    if (nextBtn) {
      nextBtn.addEventListener('click', () => {
        if (!isTransitioning) {
          goToSlide(currentSlide + 1);
        }
      });
    }

    // Indicadores
    indicators.forEach((indicator, index) => {
      indicator.addEventListener('click', () => {
        if (!isTransitioning && index !== currentSlide) {
          goToSlide(index);
        }
      });
    });

    // Teclado
    document.addEventListener('keydown', handleKeyboard);

    // Touch/Swipe
    if (carouselTrack) {
      setupTouchEvents();
    }

    // Pause autoplay on hover
    const carousel = document.querySelector('.programs-carousel');
    if (carousel && config.autoplay) {
      carousel.addEventListener('mouseenter', stopAutoplay);
      carousel.addEventListener('mouseleave', startAutoplay);
    }

    // Responsive
    window.addEventListener('resize', debounce(handleResize, 250));

    console.log('🎮 Event listeners configurados');
  }

  // ==========================================
  // NAVEGACIÓN DEL CARRUSEL CON LÍMITES
  // ==========================================
  function goToSlide(slideIndex) {
    if (isTransitioning) return;

    // APLICAR LÍMITES ESTRICTOS
    if (slideIndex < 0) {
      slideIndex = totalSlides - 1; // IR AL ÚLTIMO SLIDE (3)
    } else if (slideIndex >= totalSlides) {
      slideIndex = 0; // VOLVER AL PRIMER SLIDE
    }

    if (slideIndex === currentSlide) return;

    isTransitioning = true;

    // Aplicar transición
    carouselTrack.classList.add('transitioning');
    
    // Calcular desplazamiento
    const translateX = -slideIndex * 100;
    carouselTrack.style.transform = `translateX(${translateX}%)`;

    // Actualizar slide actual
    currentSlide = slideIndex;

    // Actualizar UI
    updateIndicators();
    updateCounter();
    updateNavigationButtons();

    // Quitar flag de transición después de la animación
    setTimeout(() => {
      isTransitioning = false;
      carouselTrack.classList.remove('transitioning');
    }, config.transitionDuration);

    console.log(`🎠 Navegando a slide ${currentSlide + 1}/${totalSlides}`);
  }

  // ==========================================
  // ACTUALIZAR INDICADORES
  // ==========================================
  function updateIndicators() {
    indicators.forEach((indicator, index) => {
      if (index === currentSlide) {
        indicator.classList.add('active');
      } else {
        indicator.classList.remove('active');
      }
    });
  }

  // ==========================================
  // ACTUALIZAR CONTADOR (CORRECTO)
  // ==========================================
  function updateCounter() {
    const currentSlideElement = document.querySelector('.current-slide');
    const totalSlidesElement = document.querySelector('.total-slides');
    
    if (currentSlideElement) {
      currentSlideElement.textContent = currentSlide + 1;
    }
    
    if (totalSlidesElement) {
      totalSlidesElement.textContent = totalSlides; // SIEMPRE 3 MÁXIMO
    }
  }

  // ==========================================
  // ACTUALIZAR BOTONES DE NAVEGACIÓN
  // ==========================================
  function updateNavigationButtons() {
    const prevBtn = document.querySelector('.carousel-prev');
    const nextBtn = document.querySelector('.carousel-next');

    // LOS BOTONES SIEMPRE ESTÁN HABILITADOS PARA NAVEGACIÓN CIRCULAR
    if (prevBtn) {
      prevBtn.disabled = false;
    }
    
    if (nextBtn) {
      nextBtn.disabled = false;
    }
  }

  // ==========================================
  // ACTUALIZAR CARRUSEL COMPLETO
  // ==========================================
  function updateCarousel() {
    updateIndicators();
    updateCounter();
    updateNavigationButtons();
    
    // Aplicar posición inicial sin animación
    carouselTrack.style.transform = `translateX(-${currentSlide * 100}%)`;
  }

  // ==========================================
  // AUTOPLAY CON LÍMITES
  // ==========================================
  function startAutoplay() {
    if (!config.autoplay) return;
    
    stopAutoplay();
    
    autoplayInterval = setInterval(() => {
      if (!isTransitioning) {
        const nextSlide = currentSlide + 1;
        if (nextSlide >= totalSlides) {
          goToSlide(0); // VOLVER AL INICIO
        } else {
          goToSlide(nextSlide);
        }
      }
    }, config.autoplayDelay);
    
    console.log('▶️ Autoplay iniciado');
  }

  function stopAutoplay() {
    if (autoplayInterval) {
      clearInterval(autoplayInterval);
      autoplayInterval = null;
      console.log('⏸️ Autoplay detenido');
    }
  }

  // ==========================================
  // EVENTOS DE TECLADO
  // ==========================================
  function handleKeyboard(event) {
    if (isTransitioning) return;

    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault();
        goToSlide(currentSlide - 1);
        break;
      case 'ArrowRight':
        event.preventDefault();
        goToSlide(currentSlide + 1);
        break;
      case 'Home':
        event.preventDefault();
        goToSlide(0);
        break;
      case 'End':
        event.preventDefault();
        goToSlide(totalSlides - 1);
        break;
    }
  }

  // ==========================================
  // EVENTOS TOUCH/SWIPE
  // ==========================================
  function setupTouchEvents() {
    let startX = 0;
    let startY = 0;
    let isDragging = false;
    const threshold = 50;

    carouselTrack.addEventListener('touchstart', (e) => {
      startX = e.touches[0].clientX;
      startY = e.touches[0].clientY;
      isDragging = true;
      stopAutoplay();
    }, { passive: true });

    carouselTrack.addEventListener('touchmove', (e) => {
      if (!isDragging) return;
      
      const deltaX = Math.abs(e.touches[0].clientX - startX);
      const deltaY = Math.abs(e.touches[0].clientY - startY);
      
      if (deltaX > deltaY) {
        e.preventDefault();
      }
    }, { passive: false });

    carouselTrack.addEventListener('touchend', (e) => {
      if (!isDragging) return;
      
      const endX = e.changedTouches[0].clientX;
      const deltaX = startX - endX;

      if (Math.abs(deltaX) > threshold) {
        if (deltaX > 0) {
          goToSlide(currentSlide + 1);
        } else {
          goToSlide(currentSlide - 1);
        }
      }

      isDragging = false;
      
      if (config.autoplay) {
        setTimeout(startAutoplay, 2000);
      }
    }, { passive: true });

    console.log('👆 Eventos touch configurados');
  }

  // ==========================================
  // RESPONSIVE
  // ==========================================
  function handleResize() {
    console.log('📱 Manejando resize...');
    updateCarousel();
  }

  // ==========================================
  // UTILIDADES
  // ==========================================
  function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }

  // ==========================================
  // INICIALIZAR
  // ==========================================
  init();
}

// ==========================================
// EVENTOS DE INICIALIZACIÓN
// ==========================================
document.addEventListener("DOMContentLoaded", () => {
  setTimeout(initProgramsCarousel, 100);
});

document.addEventListener("turbo:load", () => {
  setTimeout(initProgramsCarousel, 200);
});

document.addEventListener("turbo:render", () => {
  setTimeout(initProgramsCarousel, 150);
});

// Cleanup para Turbo
document.addEventListener('turbo:before-visit', () => {
  if (window.programsCarousel) {
    window.programsCarousel.stopAutoplay();
    window.programsCarousel = null;
    console.log('🧹 Limpiando carrusel de programas para navegación Turbo');
  }
});

console.log("🎠 Sistema de carrusel cargado - VERSIÓN CON LÍMITE DE 3 SLIDES");