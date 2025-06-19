// SISTEMA DE HOME MEJORADO - CORREGIDO PARA TURBO
function initIncubaHome() {
  
  // Verificar si estamos en la página de inicio
  const heroSection = document.querySelector('.hero');
  if (!heroSection) {
    console.log('📍 No es la página de inicio, saltando inicialización de home');
    return;
  }
  
  if (window.incubaHomeInitialized) {
    console.log('🔄 Sistema ya inicializado, reiniciando...');
    cleanupHome();
  }
  
  window.incubaHomeInitialized = true;
  window.incubaAnimationFrames = [];
  console.log('🚀 Inicializando home con JavaScript');

  // ==========================================
  // EFECTO FADE IN SUTIL PARA TODA LA PÁGINA
  // ==========================================
  function initPageFadeIn() {
    const background = document.querySelector('.background');
    
    // Elementos principales a animar
    const elementsToFade = [
      '.hero__content',
      '.hero__images', 
      '.stats',
      '.partners'
    ];
    
    // Aplicar fade inicial
    elementsToFade.forEach((selector, index) => {
      const element = document.querySelector(selector);
      if (element) {
        element.style.opacity = '0';
        element.style.transform = 'translateY(15px)';
        element.style.transition = 'all 0.6s ease-out';
        
        // Animar con delay escalonado
        setTimeout(() => {
          element.style.opacity = '1';
          element.style.transform = 'translateY(0)';
        }, 100 + (index * 150));
      }
    });
    
    // Fade especial para el background
    if (background) {
      background.style.opacity = '0';
      background.style.transition = 'opacity 0.4s ease-out';
      setTimeout(() => {
        background.style.opacity = '1';
      }, 50);
    }
    
    console.log('✨ Efecto fade-in aplicado');
  }

  // ==========================================
  // SISTEMA DE PUNTOS MÓVILES JAVASCRIPT
  // ==========================================
  function initFloatingDots() {
    const background = document.querySelector('.background');
    if (!background) {
      console.warn('❌ No se encontró .background');
      return;
    }

    // Limpiar contenedor anterior si existe
    const existingContainer = background.querySelector('.floating-dots-container');
    if (existingContainer) {
      existingContainer.remove();
    }

    // Crear contenedor para los puntos
    const dotsContainer = document.createElement('div');
    dotsContainer.style.cssText = `
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
      z-index: 5;
      opacity: 1;
    `;
    dotsContainer.className = 'floating-dots-container';
    background.appendChild(dotsContainer);
    
    // Aplicar fade-in manual para los círculos
    dotsContainer.style.opacity = '0';
    dotsContainer.style.transition = 'opacity 0.8s ease-out';
    setTimeout(() => {
      dotsContainer.style.opacity = '1';
    }, 600);

    // Configuración de las MANCHAS
    const dots = [
      {
        size: 150,
        color: 'rgba(59, 130, 246, 0.4)',
        x: 15,
        y: 25,
        speedX: 0.3,
        speedY: 0.2,
        range: 40
      },
      {
        size: 100,
        color: 'rgba(0, 204, 102, 0.5)',
        x: 70,
        y: 40,
        speedX: 0.2,
        speedY: 0.3,
        range: 35
      },
      {
        size: 130,
        color: 'rgba(59, 130, 246, 0.3)',
        x: 85,
        y: 15,
        speedX: 0.25,
        speedY: 0.15,
        range: 30
      },
      {
        size: 80,
        color: 'rgba(0, 204, 102, 0.6)',
        x: 10,
        y: 70,
        speedX: 0.15,
        speedY: 0.4,
        range: 45
      },
      {
        size: 110,
        color: 'rgba(59, 130, 246, 0.35)',
        x: 45,
        y: 80,
        speedX: 0.4,
        speedY: 0.1,
        range: 38
      },
      {
        size: 90,
        color: 'rgba(0, 204, 102, 0.4)',
        x: 90,
        y: 60,
        speedX: 0.2,
        speedY: 0.35,
        range: 32
      }
    ];

    // Crear elementos DOM para cada punto
    const dotElements = dots.map((dotConfig, index) => {
      const dot = document.createElement('div');
      dot.style.cssText = `
        position: absolute;
        width: ${dotConfig.size}px;
        height: ${dotConfig.size}px;
        background: radial-gradient(circle, ${dotConfig.color} 0%, transparent 70%);
        border-radius: 50%;
        left: ${dotConfig.x}%;
        top: ${dotConfig.y}%;
        opacity: 0.3;
        transition: opacity 0.3s ease;
        will-change: transform;
      `;
      dotsContainer.appendChild(dot);
      
      return {
        element: dot,
        config: dotConfig,
        baseX: dotConfig.x,
        baseY: dotConfig.y,
        time: Math.random() * Math.PI * 2
      };
    });

    // Función de animación
    function animateDots() {
      if (!window.incubaHomeInitialized) return;
      
      dotElements.forEach((dot) => {
        dot.time += 0.01;
        
        const offsetX = Math.sin(dot.time * dot.config.speedX) * dot.config.range;
        const offsetY = Math.cos(dot.time * dot.config.speedY) * dot.config.range;
        
        const scale = 1 + Math.sin(dot.time * 0.5) * 0.2;
        const opacity = 0.6 + Math.sin(dot.time * 0.3) * 0.3;
        
        dot.element.style.transform = `
          translate(${offsetX}px, ${offsetY}px) 
          scale(${scale})
        `;
        dot.element.style.opacity = opacity;
      });
      
      const frameId = requestAnimationFrame(animateDots);
      window.incubaAnimationFrames.push(frameId);
    }

    animateDots();
    console.log('✅ Sistema de puntos móviles inicializado');
    return dotElements;
  }

  // ==========================================
  // EFECTOS ADICIONALES
  // ==========================================
  function initScrollAnimations() {
    if (!('IntersectionObserver' in window)) return;

    // Limpiar observador anterior
    if (window.incubaScrollObserver) {
      window.incubaScrollObserver.disconnect();
    }

    window.incubaScrollObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-in');
          
          if (entry.target.classList.contains('stats__item')) {
            const delay = Array.from(entry.target.parentNode.children).indexOf(entry.target) * 150;
            entry.target.style.animationDelay = `${delay}ms`;
          }
        }
      });
    }, {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px'
    });

    document.querySelectorAll('.animate-on-scroll, .stats__item, .hero__image-container').forEach(el => {
      window.incubaScrollObserver.observe(el);
    });

    console.log('✅ Animaciones de scroll inicializadas');
  }

  function initCounters() {
    const counters = document.querySelectorAll('.stats__number');
    
    // Limpiar observador anterior
    if (window.incubaCounterObserver) {
      window.incubaCounterObserver.disconnect();
    }

    window.incubaCounterObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const counter = entry.target;
          const text = counter.textContent;
          const number = parseFloat(text.replace(/[^\d.]/g, ''));
          const suffix = text.replace(/[\d.,]/g, '');
          
          if (number > 0) {
            let current = 0;
            const increment = number / 60;
            const duration = 2000;
            const stepTime = duration / 60;
            
            const timer = setInterval(() => {
              current += increment;
              if (current >= number) {
                current = number;
                clearInterval(timer);
              }
              
              let display = Math.floor(current);
              
              if (display >= 1000) {
                if (display >= 1000000) {
                  display = (display / 1000000).toFixed(1) + 'M';
                } else {
                  display = (display / 1000).toFixed(1) + 'K';
                }
              }
              
              counter.textContent = display + suffix;
            }, stepTime);
          }
          
          window.incubaCounterObserver.unobserve(counter);
        }
      });
    }, { threshold: 0.5 });

    counters.forEach(counter => window.incubaCounterObserver.observe(counter));
    console.log('✅ Contadores animados inicializados');
  }

  function initTitleEffects() {
    const titleParts = document.querySelectorAll('.hero__title-part');
    
    // Limpiar animaciones anteriores
    if (window.incubaTitleFrames) {
      window.incubaTitleFrames.forEach(frame => {
        if (frame) cancelAnimationFrame(frame);
      });
    }
    window.incubaTitleFrames = [];
    
    titleParts.forEach((part, index) => {
      let time = index * Math.PI;
      let isHovered = false;
      
      function animateLevitation() {
        if (!window.incubaHomeInitialized) return;
        
        if (!isHovered) {
          time += 0.02;
          
          const yOffset = Math.sin(time) * 20;
          const scale = 1 + Math.sin(time) * 0.03;
          
          part.style.transform = `translateY(${yOffset}px) scale(${scale})`;
          part.style.transition = 'none';
        }
        
        const frameId = requestAnimationFrame(animateLevitation);
        window.incubaTitleFrames[index] = frameId;
      }
      
      window.incubaTitleFrames[index] = requestAnimationFrame(animateLevitation);
      
      part.addEventListener('mouseenter', () => {
        isHovered = true;
        
        if (window.incubaTitleFrames[index]) {
          cancelAnimationFrame(window.incubaTitleFrames[index]);
        }
        
        part.style.transition = 'all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)';
        part.style.transform = 'scale(1.1) translateY(-15px)';
        part.style.filter = 'brightness(1.3) drop-shadow(0 12px 30px currentColor)';
        
        titleParts.forEach((otherPart, otherIndex) => {
          if (otherIndex !== index) {
            if (window.incubaTitleFrames[otherIndex]) {
              cancelAnimationFrame(window.incubaTitleFrames[otherIndex]);
            }
            otherPart.style.transition = 'all 0.4s ease';
            otherPart.style.opacity = '0.7';
            otherPart.style.transform = 'scale(0.95)';
          }
        });
      });

      part.addEventListener('mouseleave', () => {
        isHovered = false;
        
        titleParts.forEach((titlePart, partIndex) => {
          titlePart.style.transition = 'all 0.4s ease';
          titlePart.style.filter = '';
          titlePart.style.opacity = '1';
          
          setTimeout(() => {
            let partTime = partIndex * Math.PI;
            
            function restartLevitation() {
              if (!window.incubaHomeInitialized) return;
              if (!titlePart.matches(':hover')) {
                partTime += 0.02;
                const yOffset = Math.sin(partTime) * 20;
                const scale = 1 + Math.sin(partTime) * 0.03;
                
                titlePart.style.transition = 'none';
                titlePart.style.transform = `translateY(${yOffset}px) scale(${scale})`;
              }
              
              const frameId = requestAnimationFrame(restartLevitation);
              window.incubaTitleFrames[partIndex] = frameId;
            }
            
            window.incubaTitleFrames[partIndex] = requestAnimationFrame(restartLevitation);
          }, 400);
        });
      });
    });

    console.log('✅ Efectos de título inicializados');
  }

  function initImageEffects() {
    const imageContainers = document.querySelectorAll('.hero__image-container');
    
    imageContainers.forEach((container, index) => {
      // Remover listeners anteriores si existen
      if (container._incubaMouseEnter) {
        container.removeEventListener('mouseenter', container._incubaMouseEnter);
      }
      if (container._incubaMouseLeave) {
        container.removeEventListener('mouseleave', container._incubaMouseLeave);
      }
      
      // Crear las funciones de evento
      container._incubaMouseEnter = () => {
        container.style.animationPlayState = 'paused';
        container.style.transform = 'translateY(-20px) scale(1.08)';
        container.style.filter = 'brightness(1.15) contrast(1.1) drop-shadow(0 20px 40px rgba(0, 0, 0, 0.3))';
        container.style.transition = 'all 0.5s cubic-bezier(0.34, 1.56, 0.64, 1)';
        container.style.zIndex = '100';
        
        imageContainers.forEach((other, otherIndex) => {
          if (otherIndex !== index) {
            other.style.animationPlayState = 'paused';
            const distance = Math.abs(otherIndex - index);
            other.style.transform = `scale(${0.95 - distance * 0.02}) translateY(${distance * 3}px)`;
            other.style.opacity = '0.7';
            other.style.filter = 'blur(1px)';
          }
        });
      };

      container._incubaMouseLeave = () => {
        imageContainers.forEach((imageContainer) => {
          imageContainer.style.animationPlayState = 'running';
          imageContainer.style.transform = '';
          imageContainer.style.filter = '';
          imageContainer.style.opacity = '';
          imageContainer.style.transition = 'all 0.5s ease';
          imageContainer.style.zIndex = '';
        });
      };
      
      // Agregar los nuevos eventos
      container.addEventListener('mouseenter', container._incubaMouseEnter);
      container.addEventListener('mouseleave', container._incubaMouseLeave);
    });

    console.log('✅ Efectos de imagen inicializados');
  }

  function disableParticles() {
    const canvas = document.getElementById("particles");
    if (canvas) {
      canvas.style.display = 'none';
      console.log('❌ Canvas de partículas deshabilitado');
    }
  }

  // ==========================================
  // FUNCIÓN DE LIMPIEZA
  // ==========================================
  function cleanupHome() {
    // Limpiar animaciones
    if (window.incubaAnimationFrames) {
      window.incubaAnimationFrames.forEach(frame => {
        if (frame) cancelAnimationFrame(frame);
      });
      window.incubaAnimationFrames = [];
    }
    
    if (window.incubaTitleFrames) {
      window.incubaTitleFrames.forEach(frame => {
        if (frame) cancelAnimationFrame(frame);
      });
      window.incubaTitleFrames = [];
    }
    
    // Limpiar observadores
    if (window.incubaScrollObserver) {
      window.incubaScrollObserver.disconnect();
    }
    
    if (window.incubaCounterObserver) {
      window.incubaCounterObserver.disconnect();
    }
    
    // Limpiar contenedor de puntos
    const dotsContainer = document.querySelector('.floating-dots-container');
    if (dotsContainer) {
      dotsContainer.remove();
    }
    
    console.log('🧹 Limpieza de home completada');
  }

  // ==========================================
  // INICIALIZACIÓN PRINCIPAL
  // ==========================================
  try {
    console.log('🚀 Iniciando sistemas de home...');
    
    // Esperar a que el header esté listo
    const waitForHeader = () => {
      return new Promise((resolve) => {
        if (window.headerInitialized || document.querySelector('.scroll-progress-bar')) {
          resolve();
        } else {
          // Esperar un poco más
          setTimeout(() => {
            resolve();
          }, 200);
        }
      });
    };

    waitForHeader().then(() => {
      // APLICAR FADE IN PRIMERO
      initPageFadeIn();
      
      disableParticles();
      initFloatingDots();
      initScrollAnimations();
      initCounters();
      initTitleEffects();
      initImageEffects();

      window.dispatchEvent(new CustomEvent('incubaHomeReady', {
        detail: { 
          timestamp: Date.now(),
          features: ['floating-dots', 'animations', 'fade-in'],
          particles: false
        }
      }));

      console.log('🎉 Sistema de home completamente inicializado');
    });

  } catch (error) {
    console.error('❌ Error inicializando home:', error);
  }
}

// ==========================================
// EVENTOS DE INICIALIZACIÓN
// ==========================================
document.addEventListener("DOMContentLoaded", () => {
  // Pequeño delay para asegurar que el header se inicialice primero
  setTimeout(initIncubaHome, 100);
});

document.addEventListener("turbo:load", () => {
  // Delay más largo para navegación Turbo
  setTimeout(initIncubaHome, 200);
});

document.addEventListener("turbo:render", () => {
  setTimeout(initIncubaHome, 150);
});

// Cleanup para Turbo
document.addEventListener('turbo:before-visit', () => {
  if (window.incubaHomeInitialized) {
    window.incubaHomeInitialized = false;
    
    // Limpiar animaciones
    if (window.incubaAnimationFrames) {
      window.incubaAnimationFrames.forEach(frame => {
        if (frame) cancelAnimationFrame(frame);
      });
      window.incubaAnimationFrames = [];
    }
    
    if (window.incubaTitleFrames) {
      window.incubaTitleFrames.forEach(frame => {
        if (frame) cancelAnimationFrame(frame);
      });
      window.incubaTitleFrames = [];
    }
    
    // Limpiar observadores
    if (window.incubaScrollObserver) {
      window.incubaScrollObserver.disconnect();
    }
    
    if (window.incubaCounterObserver) {
      window.incubaCounterObserver.disconnect();
    }
    
    console.log('🧹 Limpiando home para navegación Turbo');
  }
});

console.log("🎉 Enhanced Home cargado - VERSIÓN CORREGIDA PARA TURBO");
