// Utilidades de la aplicación
const fs = require('fs');
const path = require('path');

const Utils = {
  // Crear directorio si no existe
  ensureDir: (dirPath) => {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
  },

  // Validar email
  isValidEmail: (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  },

  // Generar nombre de archivo único
  generateFileName: (originalName) => {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 15);
    const ext = path.extname(originalName);
    return `${timestamp}-${random}${ext}`;
  },

  // Validar tipo de archivo
  isValidImageFile: (mimetype) => {
    const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    return validTypes.includes(mimetype);
  },

  // Formatear fecha
  formatDate: (date) => {
    if (!date) return 'N/A';
    return new Date(date).toLocaleDateString('es-ES', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  },

  // Formatear precio
  formatPrice: (price) => {
    return '$' + parseFloat(price).toFixed(2);
  },

  // Validar ISBN
  isValidISBN: (isbn) => {
    // ISBN-13 o ISBN-10 sin guiones
    const isbnRegex = /^(\d{9}[\dXx]|\d{13})$/;
    return isbnRegex.test(isbn.replace(/-/g, ''));
  },

  // Paginar array
  paginate: (array, page, pageSize) => {
    const totalPages = Math.ceil(array.length / pageSize);
    const startIndex = (page - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    
    return {
      items: array.slice(startIndex, endIndex),
      currentPage: page,
      totalPages: totalPages,
      totalItems: array.length,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1
    };
  }
};

module.exports = Utils;
