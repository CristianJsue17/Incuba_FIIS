document.addEventListener("DOMContentLoaded", () => {
    // Verificar si estamos en vista móvil para añadir el logo
    console.log("Prueba de consola");
    function checkMobileView() {
      if (window.innerWidth <= 480) {
        // Si la sección izquierda está oculta y no existe el logo móvil, lo añadimos
        const leftSection = document.querySelector(".login__left");
        const formHeader = document.querySelector(".login__form-header");
  
        if (
          window.getComputedStyle(leftSection).display === "none" &&
          !document.querySelector(".login__mobile-logo")
        ) {
          const mobileLogoDiv = document.createElement("div");
          mobileLogoDiv.className = "login__mobile-logo";
  
          const logoText = document.createElement("div");
          logoText.className = "login__mobile-logo-text";
          logoText.textContent = "co";
  
          mobileLogoDiv.appendChild(logoText);
          formHeader.parentNode.insertBefore(mobileLogoDiv, formHeader);
        }
      }
    }
  
    // Ejecutar al cargar y al cambiar el tamaño de la ventana
    checkMobileView();
    window.addEventListener("resize", checkMobileView);
  
    // Toggle de visibilidad de la contraseña
    function setupPasswordToggle(inputId, toggleId) {
      const passwordInput = document.getElementById(inputId);
      const passwordToggle = document.getElementById(toggleId);
  
      passwordToggle.addEventListener("click", () => {
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
      });
    }
  
    // Configurar toggles para ambos campos de contraseña
    setupPasswordToggle("password", "passwordToggle");
    setupPasswordToggle("confirmPassword", "confirmPasswordToggle");
  
    // Validación de fortaleza de contraseña
    const passwordInput = document.getElementById("password");
    const passwordStrength = document.getElementById("passwordStrength");
    const passwordStrengthText = document.getElementById("passwordStrengthText");
  
    passwordInput.addEventListener("input", function () {
      const password = this.value;
      let strength = 0;
      let status = "";
  
      // Criterios de fortaleza
      if (password.length >= 8) strength += 1;
      if (password.match(/[a-z]/) && password.match(/[A-Z]/)) strength += 1;
      if (password.match(/\d/)) strength += 1;
      if (password.match(/[^a-zA-Z\d]/)) strength += 1;
  
      // Actualizar indicador visual
      passwordStrength.className = "password-strength__indicator";
  
      switch (strength) {
        case 0:
          passwordStrengthText.textContent = "Muy débil";
          break;
        case 1:
          passwordStrength.classList.add("weak");
          passwordStrengthText.textContent = "Débil";
          status = "weak";
          break;
        case 2:
          passwordStrength.classList.add("medium");
          passwordStrengthText.textContent = "Media";
          status = "medium";
          break;
        case 3:
          passwordStrength.classList.add("strong");
          passwordStrengthText.textContent = "Fuerte";
          status = "strong";
          break;
        case 4:
          passwordStrength.classList.add("very-strong");
          passwordStrengthText.textContent = "Muy fuerte";
          status = "very-strong";
          break;
      }
  
      validateForm();
    });
  
    // Validación de coincidencia de contraseñas
    const confirmPasswordInput = document.getElementById("confirmPassword");
  
    confirmPasswordInput.addEventListener("input", () => {
      validateForm();
    });
  
    // Validación del email
    const emailInput = document.getElementById("email");
  
    emailInput.addEventListener("input", () => {
      validateForm();
    });
  
    // Función para validar todo el formulario
    function validateForm() {
      const signupButton = document.getElementById("signupButton");
      const password = passwordInput.value;
      const confirmPassword = confirmPasswordInput.value;
      const email = emailInput.value;
  
      // Verificar que todos los campos estén completos
      const allFieldsFilled = password && confirmPassword && email;
  
      // Verificar que las contraseñas coincidan
      const passwordsMatch = password === confirmPassword;
  
      // Verificar que la contraseña tenga al menos fortaleza media (2 criterios)
      let passwordStrength = 0;
      if (password.length >= 8) passwordStrength += 1;
      if (password.match(/[a-z]/) && password.match(/[A-Z]/))
        passwordStrength += 1;
      if (password.match(/\d/)) passwordStrength += 1;
      if (password.match(/[^a-zA-Z\d]/)) passwordStrength += 1;
  
      const strongEnoughPassword = passwordStrength >= 2;
  
      // Verificar formato de email
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      const validEmail = emailRegex.test(email);
  
      // Habilitar/deshabilitar botón según validación
      if (
        allFieldsFilled &&
        passwordsMatch &&
        strongEnoughPassword &&
        validEmail
      ) {
        signupButton.disabled = false;
      } else {
        signupButton.disabled = true;
      }
    }
  
    // Animación adicional para los círculos
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
  });