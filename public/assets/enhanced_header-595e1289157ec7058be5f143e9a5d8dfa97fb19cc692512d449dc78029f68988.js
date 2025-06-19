document.addEventListener("DOMContentLoaded", initHeader);
document.addEventListener("turbo:load", initHeader);
document.addEventListener("turbo:render", initHeader);

function initHeader() {
  // Limpiar listeners anteriores
  if (window.headerInitialized) {
    console.log('🔄 Header ya inicializado, limpiando...');
    cleanupHeader();
  }
  
  window.headerInitialized = true;
  console.log('🚀 Inicializando header');

  // ==========================================
  // CONFIGURACIÓN Y VARIABLES
  // ==========================================
  const header = document.querySelector(".header");
  const hamburgerBtn = document.querySelector(".header__hamburger");
  const nav = document.querySelector(".header__nav");
  const dropdownItems = document.querySelectorAll(".header__menu-item--has-dropdown");
  const menuItems = document.querySelectorAll(".header__menu-item");
  const actionBtns = document.querySelectorAll(".header__action-btn");
  const menuLinks = document.querySelectorAll(".header__menu-link");
  
  if (!header) return; // Si no hay header, salir
  
  let lastScrollTop = 0;
  let ticking = false;

  // ==========================================
  // FUNCIÓN PARA MARCAR PÁGINA ACTIVA
  // ==========================================
  function setActiveMenuItem() {
    const currentPath = window.location.pathname;
    
    menuLinks.forEach(link => {
      // Quitar clase activa de todos
      link.classList.remove('active');
      
      // Obtener el href del enlace
      const linkPath = link.getAttribute('href');
      
      // Si el path actual coincide con el href del enlace
      if (linkPath && (currentPath === linkPath || 
          (linkPath !== '/' && currentPath.includes(linkPath)))) {
        link.classList.add('active');
      }
      
      // Casos especiales para páginas específicas
      if (currentPath === '/' && linkPath === '/') {
        link.classList.add('active');
      }
    });
  }

  // ==========================================
  // TOGGLE MENÚ HAMBURGUESA
  // ==========================================
  if (hamburgerBtn) {
    hamburgerBtn.addEventListener("click", handleHamburgerClick);
  }

  function handleHamburgerClick(e) {
    e.stopPropagation();
    toggleMobileMenu();
  }

  function toggleMobileMenu() {
    const isOpen = header.classList.contains("header--menu-open");
    
    if (isOpen) {
      closeMobileMenu();
    } else {
      openMobileMenu();
    }
  }

  function openMobileMenu() {
    header.classList.add("header--menu-open");
    document.body.classList.add("no-scroll");
    
    // Animar entrada del menú
    if (nav) {
      nav.style.visibility = 'visible';
    }
    
    // Animar elementos del menú con delay
    menuItems.forEach((item, index) => {
      setTimeout(() => {
        item.style.opacity = '1';
        item.style.transform = 'translateX(0)';
      }, index * 50);
    });
  }

  function closeMobileMenu() {
    header.classList.remove("header--menu-open");
    document.body.classList.remove("no-scroll");
    
    // Cerrar todos los dropdowns abiertos
    dropdownItems.forEach((item) => {
      item.classList.remove("active");
    });
  }

  // ==========================================
  // MANEJO DE DROPDOWNS
  // ==========================================
  dropdownItems.forEach((item) => {
    const link = item.querySelector(".header__menu-link");

    // Desktop: hover
    if (window.innerWidth > 768) {
      item.addEventListener("mouseenter", () => openDropdown(item));
      item.addEventListener("mouseleave", () => closeDropdown(item));
    }

    // Mobile: click
    if (link) {
      link.addEventListener("click", (e) => {
        if (window.innerWidth <= 768) {
          e.preventDefault();
          toggleDropdown(item);
        }
      });
    }
  });

  function openDropdown(item) {
    const dropdown = item.querySelector(".header__dropdown");
    if (dropdown) {
      dropdown.style.opacity = '1';
      dropdown.style.visibility = 'visible';
      dropdown.style.transform = 'translateY(0)';
    }
  }

  function closeDropdown(item) {
    const dropdown = item.querySelector(".header__dropdown");
    if (dropdown) {
      dropdown.style.opacity = '0';
      dropdown.style.visibility = 'hidden';
      dropdown.style.transform = 'translateY(10px)';
    }
  }

  function toggleDropdown(item) {
    const isActive = item.classList.contains("active");
    
    // Cerrar todos los otros dropdowns
    dropdownItems.forEach((otherItem) => {
      if (otherItem !== item) {
        otherItem.classList.remove("active");
      }
    });

    // Toggle el dropdown actual
    if (isActive) {
      item.classList.remove("active");
    } else {
      item.classList.add("active");
    }
  }

  // ==========================================
  // EFECTOS DE SCROLL - CORREGIDO
  // ==========================================
  function handleScroll() {
    if (!ticking) {
      requestAnimationFrame(updateHeader);
      ticking = true;
    }
  }

  function updateHeader() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    
    // Añadir clase de scroll
    if (scrollTop > 20) {
      header.classList.add("header--scrolled");
    } else {
      header.classList.remove("header--scrolled");
    }

    // Efecto parallax sutil en el logo (opcional)
    const logo = document.querySelector(".header__logo-img");
    if (logo && scrollTop < 500) {
      const parallaxValue = scrollTop * 0.02;
      logo.style.transform = `translateY(${parallaxValue}px)`;
    }

    // Actualizar barra de progreso
    updateScrollProgress();

    lastScrollTop = scrollTop <= 0 ? 0 : scrollTop;
    ticking = false;
  }

  // Asignar evento de scroll
  window.addEventListener("scroll", handleScroll);

  // ==========================================
  // CERRAR MENÚ AL HACER CLICK FUERA
  // ==========================================
  function handleDocumentClick(e) {
    if (!header.contains(e.target) && header.classList.contains("header--menu-open")) {
      closeMobileMenu();
    }

    // Cerrar dropdowns al hacer click fuera
    if (window.innerWidth > 768) {
      dropdownItems.forEach((item) => {
        if (!item.contains(e.target)) {
          closeDropdown(item);
        }
      });
    }
  }

  document.addEventListener("click", handleDocumentClick);

  // ==========================================
  // ANIMACIONES DE ENTRADA
  // ==========================================
  function initHeaderAnimations() {
    const logoLink = document.querySelector(".header__logo-link");
    if (logoLink) {
      logoLink.style.opacity = '0';
      logoLink.style.transform = 'translateY(-20px)';
      
      setTimeout(() => {
        logoLink.style.transition = 'all 0.6s ease';
        logoLink.style.opacity = '1';
        logoLink.style.transform = 'translateY(0)';
      }, 100);
    }

    menuItems.forEach((item, index) => {
      item.style.opacity = "0";
      item.style.transform = "translateY(-20px)";

      setTimeout(() => {
        item.style.transition = "all 0.4s ease";
        item.style.opacity = "1";
        item.style.transform = "translateY(0)";
      }, 200 + index * 100);
    });

    actionBtns.forEach((btn, index) => {
      btn.style.opacity = "0";
      btn.style.transform = "scale(0.8)";

      setTimeout(() => {
        btn.style.transition = "all 0.4s cubic-bezier(0.68, -0.55, 0.265, 1.55)";
        btn.style.opacity = "1";
        btn.style.transform = "scale(1)";
      }, 400 + index * 150);
    });
  }

  // ==========================================
  // INDICADOR DE PROGRESO DE SCROLL - MEJORADO
  // ==========================================
  function createScrollProgress() {
    // Limpiar barra anterior si existe
    const existingBar = document.querySelector('.scroll-progress-bar');
    if (existingBar) {
      existingBar.remove();
    }

    const progressBar = document.createElement("div");
    progressBar.className = 'scroll-progress-bar';
    progressBar.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 0%;
      height: 3px;
      background: linear-gradient(90deg, #3b82f6, #00cc66);
      z-index: 9999;
      transition: width 0.1s ease;
      border-radius: 0 0 2px 2px;
    `;
    
    document.body.appendChild(progressBar);
    window.scrollProgressBar = progressBar; // Guardar referencia global
  }

  function updateScrollProgress() {
    if (window.scrollProgressBar) {
      const scrollHeight = document.documentElement.scrollHeight - window.innerHeight;
      const scrollProgress = scrollHeight > 0 ? (window.scrollY / scrollHeight) * 100 : 0;
      window.scrollProgressBar.style.width = `${Math.min(scrollProgress, 100)}%`;
    }
  }

  // ==========================================
  // EFECTOS HOVER MEJORADOS
  // ==========================================
  function enhanceHoverEffects() {
    const loginBtn = document.querySelector(".header__action-btn--login");
    if (loginBtn) {
      loginBtn.addEventListener("mouseenter", () => {
        createButtonParticles(loginBtn);
      });
    }
  }

  function createButtonParticles(button) {
    const rect = button.getBoundingClientRect();
    const particleCount = 6;

    for (let i = 0; i < particleCount; i++) {
      const particle = document.createElement("div");
      particle.style.cssText = `
        position: fixed;
        width: 4px;
        height: 4px;
        background: var(--color-primary, #3b82f6);
        border-radius: 50%;
        pointer-events: none;
        z-index: 1000;
        left: ${rect.left + rect.width / 2}px;
        top: ${rect.top + rect.height / 2}px;
      `;
      
      document.body.appendChild(particle);

      const angle = (i / particleCount) * Math.PI * 2;
      const distance = 30;

      const animation = particle.animate([
        {
          transform: "translate(0, 0) scale(1)",
          opacity: 1
        },
        {
          transform: `translate(${Math.cos(angle) * distance}px, ${Math.sin(angle) * distance}px) scale(0)`,
          opacity: 0
        }
      ], {
        duration: 600,
        easing: "ease-out"
      });

      animation.onfinish = () => particle.remove();
    }
  }

  // ==========================================
  // ACCESIBILIDAD
  // ==========================================
  function enhanceAccessibility() {
    // Navegación por teclado
    function handleKeyDown(e) {
      if (e.key === "Escape" && header.classList.contains("header--menu-open")) {
        closeMobileMenu();
      }
    }

    document.addEventListener("keydown", handleKeyDown);

    // Focus management para el menú móvil
    if (hamburgerBtn) {
      hamburgerBtn.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          toggleMobileMenu();
        }
      });

      // ARIA labels dinámicos
      const updateAriaLabel = () => {
        const isOpen = header.classList.contains("header--menu-open");
        hamburgerBtn.setAttribute("aria-label", isOpen ? "Cerrar menú" : "Abrir menú");
        hamburgerBtn.setAttribute("aria-expanded", isOpen.toString());
      };

      const observer = new MutationObserver(updateAriaLabel);
      observer.observe(header, { attributes: true, attributeFilter: ["class"] });
      updateAriaLabel();
    }
  }

  // ==========================================
  // CLEANUP FUNCIÓN
  // ==========================================
  function cleanupHeader() {
    // Limpiar eventos
    window.removeEventListener("scroll", handleScroll);
    document.removeEventListener("click", handleDocumentClick);
    
    // Limpiar barra de progreso anterior
    const existingBar = document.querySelector('.scroll-progress-bar');
    if (existingBar) {
      existingBar.remove();
    }
    
    // Remover clase no-scroll
    document.body.classList.remove("no-scroll");
  }

  // ==========================================
  // AGREGAR ESTILOS NECESARIOS
  // ==========================================
  function addNoScrollClass() {
    if (!document.querySelector('#header-styles')) {
      const style = document.createElement('style');
      style.id = 'header-styles';
      style.textContent = `
        .no-scroll {
          overflow: hidden;
          height: 100vh;
        }
      `;
      document.head.appendChild(style);
    }
  }

  // ==========================================
  // INICIALIZACIÓN
  // ==========================================
  try {
    addNoScrollClass();
    setActiveMenuItem();
    initHeaderAnimations();
    createScrollProgress();
    enhanceHoverEffects();
    enhanceAccessibility();

    console.log("✅ Header inicializado correctamente");
  } catch (error) {
    console.error("❌ Error inicializando header:", error);
  }
}

// ==========================================
// CLEANUP PARA TURBO
// ==========================================
document.addEventListener('turbo:before-visit', () => {
  if (window.headerInitialized) {
    console.log('🧹 Limpiando header para navegación');
    
    // Limpiar barra de progreso
    const progressBar = document.querySelector('.scroll-progress-bar');
    if (progressBar) {
      progressBar.remove();
    }
    
    // Remover clase no-scroll
    document.body.classList.remove("no-scroll");
    
    window.headerInitialized = false;
  }
});

console.log("🎉 Enhanced Header cargado - VERSIÓN CORREGIDA PARA TURBO");
