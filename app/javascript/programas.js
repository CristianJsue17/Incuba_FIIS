// Programs Showcase JavaScript
class ProgramsShowcase {
    constructor() {
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.setupIntersectionObserver();
        this.setupCardInteractions();
    }

    setupEventListeners() {
        // Filter functionality
        const filterButtons = document.querySelectorAll('.filter-btn');
        const programCards = document.querySelectorAll('.program-card');

        filterButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                const filter = e.target.dataset.filter;
                
                // Update active button
                filterButtons.forEach(btn => btn.classList.remove('filter-btn--active'));
                e.target.classList.add('filter-btn--active');
                
                // Filter cards
                this.filterCards(programCards, filter);
            });
        });

        // Social link tracking
        const socialLinks = document.querySelectorAll('.social-link');
        socialLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const platform = this.getSocialPlatform(link);
                this.trackSocialClick(platform);
                
                // Add click animation
                link.style.transform = 'scale(0.95)';
                setTimeout(() => {
                    link.style.transform = 'scale(1.1)';
                    setTimeout(() => {
                        link.style.transform = '';
                    }, 150);
                }, 100);
            });
        });

        // Card action buttons
        const actionButtons = document.querySelectorAll('.program-card__action');
        actionButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                e.stopPropagation();
                const card = button.closest('.program-card');
                const title = card.querySelector('.program-card__title').textContent;
                this.showProjectDetails(title);
            });
        });

        // Card click handlers
        const cards = document.querySelectorAll('.program-card');
        cards.forEach(card => {
            card.addEventListener('click', () => {
                const title = card.querySelector('.program-card__title').textContent;
                this.showProjectDetails(title);
            });
        });
    }

    filterCards(cards, filter) {
        cards.forEach(card => {
            const stage = card.dataset.stage;
            const shouldShow = filter === 'all' || stage === filter;
            
            if (shouldShow) {
                card.classList.remove('program-card--hidden');
                card.style.animation = 'fadeInUp 0.6s ease forwards';
            } else {
                card.classList.add('program-card--hidden');
            }
        });
    }

    getSocialPlatform(link) {
        if (link.classList.contains('social-link--facebook')) return 'facebook';
        if (link.classList.contains('social-link--instagram')) return 'instagram';
        if (link.classList.contains('social-link--linkedin')) return 'linkedin';
        return 'unknown';
    }

    trackSocialClick(platform) {
        console.log(`Social click tracked: ${platform}`);
        // Here you would typically send analytics data
        // Example: gtag('event', 'social_click', { platform: platform });
    }

    showProjectDetails(title) {
        // Create modal or navigate to project page
        console.log(`Showing details for: ${title}`);
        
        // Example modal implementation
        const modal = this.createModal(title);
        document.body.appendChild(modal);
        
        // Animate modal appearance
        requestAnimationFrame(() => {
            modal.classList.add('modal--visible');
        });
    }

    createModal(title) {
        const modal = document.createElement('div');
        modal.className = 'modal';
        modal.innerHTML = `
            <div class="modal__backdrop"></div>
            <div class="modal__content">
                <div class="modal__header">
                    <h3 class="modal__title">${title}</h3>
                    <button class="modal__close" aria-label="Cerrar modal">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                <div class="modal__body">
                    <p>Detalles del proyecto ${title} aparecerían aquí...</p>
                    <div class="modal__actions">
                        <button class="btn btn--primary">Ver más información</button>
                        <button class="btn btn--secondary">Contactar equipo</button>
                    </div>
                </div>
            </div>
        `;

        // Add modal styles
        const style = document.createElement('style');
        style.textContent = `
            .modal {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                z-index: 1000;
                opacity: 0;
                visibility: hidden;
                transition: all 0.3s ease;
            }
            
            .modal--visible {
                opacity: 1;
                visibility: visible;
            }
            
            .modal__backdrop {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.5);
                backdrop-filter: blur(4px);
            }
            
            .modal__content {
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                background: white;
                border-radius: 16px;
                max-width: 500px;
                width: 90%;
                max-height: 80vh;
                overflow-y: auto;
            }
            
            .modal__header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 1.5rem;
                border-bottom: 1px solid #e2e8f0;
            }
            
            .modal__title {
                font-size: 1.25rem;
                font-weight: 700;
                color: #1e293b;
            }
            
            .modal__close {
                background: none;
                border: none;
                font-size: 1.25rem;
                color: #64748b;
                cursor: pointer;
                padding: 0.5rem;
                border-radius: 50%;
                transition: all 0.2s ease;
            }
            
            .modal__close:hover {
                background: #f1f5f9;
                color: #1e293b;
            }
            
            .modal__body {
                padding: 1.5rem;
            }
            
            .modal__actions {
                display: flex;
                gap: 1rem;
                margin-top: 1.5rem;
            }
            
            .btn {
                padding: 0.75rem 1.5rem;
                border-radius: 8px;
                font-weight: 500;
                cursor: pointer;
                transition: all 0.2s ease;
                border: none;
                flex: 1;
            }
            
            .btn--primary {
                background: #3b82f6;
                color: white;
            }
            
            .btn--primary:hover {
                background: #2563eb;
            }
            
            .btn--secondary {
                background: #f1f5f9;
                color: #64748b;
            }
            
            .btn--secondary:hover {
                background: #e2e8f0;
            }
        `;
        
        if (!document.querySelector('#modal-styles')) {
            style.id = 'modal-styles';
            document.head.appendChild(style);
        }

        // Close modal functionality
        const closeBtn = modal.querySelector('.modal__close');
        const backdrop = modal.querySelector('.modal__backdrop');
        
        const closeModal = () => {
            modal.classList.remove('modal--visible');
            setTimeout(() => {
                document.body.removeChild(modal);
            }, 300);
        };

        closeBtn.addEventListener('click', closeModal);
        backdrop.addEventListener('click', closeModal);

        // Close on Escape key
        const handleEscape = (e) => {
            if (e.key === 'Escape') {
                closeModal();
                document.removeEventListener('keydown', handleEscape);
            }
        };
        document.addEventListener('keydown', handleEscape);

        return modal;
    }

    setupIntersectionObserver() {
        const cards = document.querySelectorAll('.program-card');
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        });

        cards.forEach(card => {
            observer.observe(card);
        });
    }

    setupCardInteractions() {
        const cards = document.querySelectorAll('.program-card');
        
        cards.forEach(card => {
            // Add hover effects for better UX
            card.addEventListener('mouseenter', () => {
                const img = card.querySelector('.program-card__img');
                const action = card.querySelector('.program-card__action');
                
                if (img) img.style.transform = 'scale(1.05)';
                if (action) action.style.transform = 'scale(1.1)';
            });
            
            card.addEventListener('mouseleave', () => {
                const img = card.querySelector('.program-card__img');
                const action = card.querySelector('.program-card__action');
                
                if (img) img.style.transform = 'scale(1)';
                if (action) action.style.transform = 'scale(1)';
            });
        });
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new ProgramsShowcase();
});

// Add smooth scrolling for better UX
document.documentElement.style.scrollBehavior = 'smooth';

// Performance optimization: Lazy load images
if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src || img.src;
                img.classList.remove('lazy');
                imageObserver.unobserve(img);
            }
        });
    });

    document.querySelectorAll('img[data-src]').forEach(img => {
        imageObserver.observe(img);
    });
}