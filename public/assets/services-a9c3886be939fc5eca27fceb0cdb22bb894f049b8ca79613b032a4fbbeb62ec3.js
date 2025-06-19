document.addEventListener('turbo:load', function() {
  // Verificar si estamos en la página correcta antes de ejecutar animaciones
  if (document.querySelector('.servicios-container') || document.querySelector('.programas-container')) {
    console.log("En página de servicios o programas - iniciando animaciones");
    animateCards();
  }
});
