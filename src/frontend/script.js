// Script básico para a Padaria Online

// Aguarda o DOM carregar completamente
document.addEventListener('DOMContentLoaded', function() {
    
    // Smooth scroll para links internos
    const links = document.querySelectorAll('a[href^="#"]');
    
    links.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href').substring(1);
            const targetElement = document.getElementById(targetId);
            
            if (targetElement) {
                targetElement.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Destaque do menu ativo
    const navLinks = document.querySelectorAll('.nav-links a');
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    
    navLinks.forEach(link => {
        const linkPage = link.getAttribute('href');
        
        if (linkPage === currentPage || 
            (currentPage === '' && linkPage === 'index.html') ||
            (currentPage === 'index.html' && linkPage === 'index.html')) {
            link.style.color = '#F4A460';
            link.style.fontWeight = 'bold';
        }
    });
    
    // Função simples para o botão "Ver Produtos"
    const btnPrimary = document.querySelector('.btn-primary');
    
    if (btnPrimary) {
        btnPrimary.addEventListener('click', function() {
            const produtosSection = document.getElementById('produtos');
            
            if (produtosSection) {
                produtosSection.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        });
    }
    
    // Animação simples nos cards ao fazer scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observa os cards de produtos e membros da equipe
    const cards = document.querySelectorAll('.produto-card, .membro-card');
    cards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });
    
    console.log('🥖 Padaria Online carregada com sucesso!');
});