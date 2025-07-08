// contact_form.js - JavaScript para mejorar la experiencia del formulario de contacto

document.addEventListener('DOMContentLoaded', function() {
    
    // Auto-hide flash messages
    const flashMessage = document.getElementById('flashMessage');
    if (flashMessage) {
        flashMessage.classList.add('auto-hide');
        
        // También permitir cerrar manualmente
        flashMessage.addEventListener('click', function() {
            flashMessage.style.animation = 'fadeOut 0.3s ease forwards';
            setTimeout(() => {
                flashMessage.remove();
            }, 300);
        });
    }

    // Mejorar la experiencia del formulario
    const form = document.getElementById('contactForm');
    const submitBtn = form?.querySelector('.contact__submit-btn');
    
    if (form && submitBtn) {
        
        // Validación en tiempo real
        const inputs = form.querySelectorAll('.contact__input, .contact__textarea');
        
        inputs.forEach(input => {
            
            // Evento para manejar el estado del label flotante
            input.addEventListener('blur', function() {
                if (this.value.trim() !== '') {
                    this.classList.add('has-value');
                } else {
                    this.classList.remove('has-value');
                }
            });

            // Validación en tiempo real
            input.addEventListener('input', function() {
                clearTimeout(this.validationTimeout);
                
                this.validationTimeout = setTimeout(() => {
                    validateField(this);
                }, 300);
            });

        });

        // Función para validar un campo individual
        function validateField(field) {
            const value = field.value.trim();
            const fieldName = field.name;
            let isValid = true;
            let errorMessage = '';

            // Limpiar errores previos
            removeFieldError(field);

            // Validaciones específicas por campo
            switch(fieldName) {
                case 'formulario_contacto[nombre]':
                    if (value.length < 2) {
                        isValid = false;
                        errorMessage = 'El nombre debe tener al menos 2 caracteres';
                    } else if (value.length > 100) {
                        isValid = false;
                        errorMessage = 'El nombre no puede tener más de 100 caracteres';
                    }
                    break;

                case 'formulario_contacto[correo]':
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    if (!emailRegex.test(value)) {
                        isValid = false;
                        errorMessage = 'Por favor ingresa un correo electrónico válido';
                    }
                    break;

                case 'formulario_contacto[asunto]':
                    if (value.length < 3) {
                        isValid = false;
                        errorMessage = 'El asunto debe tener al menos 3 caracteres';
                    } else if (value.length > 200) {
                        isValid = false;
                        errorMessage = 'El asunto no puede tener más de 200 caracteres';
                    }
                    break;

                case 'formulario_contacto[mensaje]':
                    if (value.length < 10) {
                        isValid = false;
                        errorMessage = 'El mensaje debe tener al menos 10 caracteres';
                    } else if (value.length > 2000) {
                        isValid = false;
                        errorMessage = 'El mensaje no puede tener más de 2000 caracteres';
                    }
                    break;
            }

            // Mostrar error si no es válido
            if (!isValid) {
                showFieldError(field, errorMessage);
            }

            return isValid;
        }

        // Función para mostrar error en un campo
        function showFieldError(field, message) {
            field.classList.add('error');
            
            const errorDiv = document.createElement('div');
            errorDiv.className = 'contact__error-message';
            errorDiv.innerHTML = `
                <i class="fas fa-exclamation-circle"></i>
                ${message}
            `;

            const wrapper = field.closest('.contact__form-group');
            if (wrapper && !wrapper.querySelector('.contact__error-message')) {
                wrapper.appendChild(errorDiv);
            }
        }

        // Función para limpiar errores de un campo
        function removeFieldError(field) {
            field.classList.remove('error');
            
            const wrapper = field.closest('.contact__form-group');
            const existingError = wrapper?.querySelector('.contact__error-message');
            if (existingError) {
                existingError.remove();
            }
        }

        // Manejar envío del formulario
        form.addEventListener('submit', function(e) {
            let formIsValid = true;

            // Validar todos los campos antes de enviar
            inputs.forEach(input => {
                if (!validateField(input)) {
                    formIsValid = false;
                }
            });

            if (!formIsValid) {
                e.preventDefault();
                
                // Mostrar mensaje de error general
                showGeneralError('Por favor corrige los errores antes de enviar el formulario');
                
                // Scroll al primer error
                const firstError = form.querySelector('.contact__input.error, .contact__textarea.error');
                if (firstError) {
                    firstError.scrollIntoView({ 
                        behavior: 'smooth', 
                        block: 'center' 
                    });
                    firstError.focus();
                }
                
                return false;
            }

            // Si todo está bien, mostrar estado de carga
            submitBtn.classList.add('loading');
            submitBtn.disabled = true;
        });

        // Función para mostrar error general
        function showGeneralError(message) {
            // Remover error previo si existe
            const existingError = document.querySelector('.contact__general-error');
            if (existingError) {
                existingError.remove();
            }

            const errorDiv = document.createElement('div');
            errorDiv.className = 'alert alert-error contact__general-error';
            errorDiv.innerHTML = `
                <i class="fas fa-exclamation-triangle"></i>
                ${message}
            `;

            document.body.appendChild(errorDiv);

            // Auto-remove después de 5 segundos
            setTimeout(() => {
                if (errorDiv.parentNode) {
                    errorDiv.style.animation = 'fadeOut 0.3s ease forwards';
                    setTimeout(() => errorDiv.remove(), 300);
                }
            }, 5000);
        }

        // Contador de caracteres para el textarea
        const textarea = form.querySelector('textarea[name="formulario_contacto[mensaje]"]');
        if (textarea) {
            const maxLength = 2000;
            
            // Crear contador
            const counter = document.createElement('div');
            counter.className = 'contact__char-counter';
            counter.style.cssText = `
                text-align: right;
                font-size: 0.8rem;
                color: #64748b;
                margin-top: 0.25rem;
                font-family: var(--font-body);
            `;
            
            textarea.parentNode.appendChild(counter);

            // Actualizar contador
            function updateCounter() {
                const remaining = maxLength - textarea.value.length;
                counter.textContent = `${textarea.value.length}/${maxLength} caracteres`;
                
                if (remaining < 100) {
                    counter.style.color = '#f59e0b';
                } else if (remaining < 50) {
                    counter.style.color = '#ef4444';
                } else {
                    counter.style.color = '#64748b';
                }
            }

            textarea.addEventListener('input', updateCounter);
            updateCounter(); // Inicializar
        }
    }

    // Smooth scroll para anclas internas
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Mejorar accesibilidad
    const formGroups = document.querySelectorAll('.contact__form-group');
    formGroups.forEach(group => {
        const input = group.querySelector('.contact__input, .contact__textarea');
        const label = group.querySelector('.contact__label');
        
        if (input && label && !input.id) {
            const fieldName = input.name.replace(/[[\]]/g, '_');
            input.id = fieldName;
            label.setAttribute('for', fieldName);
        }
    });

});