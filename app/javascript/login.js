// Función principal que configura todo
function initializeLoginPage() {
  
  // SOLUCIÓN ROBUSTA: Event delegation global para el toggle
  document.removeEventListener('click', handlePasswordToggle); // Remover listeners previos
  document.addEventListener('click', handlePasswordToggle);

  // Configurar MutationObserver
  setupMutationObserver();
  
  // Configurar animaciones y otras funcionalidades
  setupCircleAnimations();
  setupAlertAutoHide();
  setupFormValidation();
  
  // Asegurar que el toggle esté listo inmediatamente
  ensurePasswordToggleReady();
}

// Función específica para manejar el toggle de contraseña
function handlePasswordToggle(e) {
  if (e.target.closest('#passwordToggle')) {
    e.preventDefault();
    e.stopPropagation();
    
    const passwordToggle = e.target.closest('#passwordToggle');
    const passwordInput = document.getElementById("password");
    
    if (passwordInput && passwordToggle) {
      if (passwordInput.type === "password") {
        passwordInput.type = "text";
        passwordToggle.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
            <line x1="1" y1="1" x2="23" y2="23"></line>
          </svg>
        `;
      } else {
        passwordInput.type = "password";
        passwordToggle.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
            <circle cx="12" cy="12" r="3"></circle>
          </svg>
        `;
      }
      
      console.log("Password toggle funcionando:", passwordInput.type);
    }
  }
}

// Asegurar que el toggle esté listo
function ensurePasswordToggleReady() {
  setTimeout(() => {
    const passwordInput = document.getElementById("password");
    const passwordToggle = document.getElementById("passwordToggle");
    
    if (passwordInput && passwordToggle) {
      // Asegurar propiedades CSS
      passwordToggle.style.cursor = 'pointer';
      passwordToggle.style.pointerEvents = 'auto';
      passwordToggle.style.zIndex = '15';
      
      // Asegurar que el input tenga el tipo correcto
      if (!passwordInput.type || (passwordInput.type !== "password" && passwordInput.type !== "text")) {
        passwordInput.type = "password";
      }
      
      console.log("Password toggle configurado correctamente");
    } else {
      console.log("Elementos de password no encontrados, reintentando...");
      // Reintentar después de un poco más de tiempo
      setTimeout(ensurePasswordToggleReady, 200);
    }
  }, 100);
}

// Configurar MutationObserver
function setupMutationObserver() {
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.type === 'childList') {
        setTimeout(ensurePasswordToggleReady, 50);
      }
    });
  });

  const formContainer = document.querySelector('.login__form-container') || document.body;
  observer.observe(formContainer, {
    childList: true,
    subtree: true
  });
}

// Configurar animaciones de círculos
function setupCircleAnimations() {
  const circles = document.querySelectorAll(".login__circle");
  circles.forEach((circle) => {
    const delay = Math.random() * 5;
    circle.style.animationDelay = `${delay}s`;

    setInterval(() => {
      const randomX = Math.random() * 10 - 5;
      const randomY = Math.random() * 10 - 5;
      circle.style.transform = `translate(${randomX}px, ${randomY}px)`;
    }, 3000);
  });
}

// Configurar auto-hide de alertas
function setupAlertAutoHide() {
  const alerts = document.querySelectorAll('.alert, .notice, .login__alert, .custom-alert');
  
  alerts.forEach(alert => {
    if (!alert.hasAttribute('data-alert-configured')) {
      alert.setAttribute('data-alert-configured', 'true');
      
      setTimeout(() => {
        if (alert.parentNode) {
          alert.style.transition = 'opacity 0.5s ease-out, transform 0.5s ease-out';
          alert.style.opacity = '0';
          alert.style.transform = 'translateY(-20px)';
          
          setTimeout(() => {
            if (alert.parentNode) {
              alert.parentNode.removeChild(alert);
            }
          }, 500);
        }
      }, 5000);

      alert.style.cursor = 'pointer';
      alert.addEventListener('click', function() {
        this.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out';
        this.style.opacity = '0';
        this.style.transform = 'translateY(-10px)';
        
        setTimeout(() => {
          if (this.parentNode) {
            this.parentNode.removeChild(this);
          }
        }, 300);
      });
    }
  });
}

// Configurar validación del formulario
function setupFormValidation() {
  const loginForm = document.querySelector(".login__form");
  
  if (loginForm && !loginForm.hasAttribute('data-validation-configured')) {
    loginForm.setAttribute('data-validation-configured', 'true');
    
    loginForm.addEventListener("submit", function (e) {
      const emailInput = document.querySelector('input[type="email"]');
      const passwordInput = document.querySelector('input[type="password"]') || 
                           document.querySelector('input[type="text"]#password');
      
      if (emailInput && passwordInput) {
        const email = emailInput.value.trim();
        const password = passwordInput.value.trim();
        
        if (!email || !password) {
          e.preventDefault();
          showCustomAlert("Por favor, complete todos los campos", "error");
          return false;
        }
      }
    });
  }
}

// Múltiples puntos de inicialización para asegurar funcionamiento
document.addEventListener("DOMContentLoaded", function() {
  console.log("DOMContentLoaded - Inicializando login");
  initializeLoginPage();
});

// Para navegación Turbo
document.addEventListener('turbo:load', function() {
  console.log("Turbo:load - Inicializando login");
  setTimeout(initializeLoginPage, 50);
});

// Para navegación tradicional
window.addEventListener('load', function() {
  console.log("Window load - Inicializando login");
  setTimeout(initializeLoginPage, 100);
});

// Backup: Inicializar después de un delay
setTimeout(function() {
  console.log("Backup initialization");
  initializeLoginPage();
}, 500);

// Función para mostrar alertas personalizadas
function showCustomAlert(message, type = "error") {
  const existingAlerts = document.querySelectorAll('.custom-alert');
  existingAlerts.forEach(alert => alert.remove());
  
  const alert = document.createElement('div');
  alert.className = `custom-alert`;
  alert.setAttribute('data-alert-configured', 'true');
  
  if (type === "error") {
    alert.style.cssText = `
      background: linear-gradient(135deg, #ff6b6b, #ee5a52) !important;
      color: white !important;
      border: 1px solid #ff4757 !important;
      border-radius: 8px !important;
      padding: 12px 16px !important;
      margin-bottom: 20px !important;
      font-size: 14px !important;
      font-weight: 500 !important;
      box-shadow: 0 4px 12px rgba(255, 107, 107, 0.2) !important;
      animation: slideInFromTop 0.3s ease-out !important;
      cursor: pointer !important;
    `;
    alert.innerHTML = `
      <i class="fas fa-exclamation-circle" style="margin-right: 8px;"></i>
      ${message}
    `;
  }
  
  const formContainer = document.querySelector('.login__form-container');
  const formHeader = document.querySelector('.login__form-header');
  
  if (formContainer && formHeader) {
    formHeader.insertAdjacentElement('afterend', alert);
    
    alert.addEventListener('click', function() {
      this.style.transition = 'opacity 0.3s ease-out';
      this.style.opacity = '0';
      setTimeout(() => this.remove(), 300);
    });
    
    setTimeout(() => {
      if (alert.parentNode) {
        alert.style.transition = 'opacity 0.3s ease-out';
        alert.style.opacity = '0';
        setTimeout(() => alert.remove(), 300);
      }
    }, 4000);
  }
}