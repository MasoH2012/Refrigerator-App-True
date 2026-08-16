document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-toggle]').forEach((button) => {
    button.addEventListener('click', () => button.classList.toggle('on'));
  });
  document.querySelectorAll('[data-toast]').forEach((button) => {
    button.addEventListener('click', () => {
      const toast = document.querySelector('.toast');
      if (!toast) return;
      toast.textContent = button.dataset.toast;
      toast.classList.add('show');
      window.setTimeout(() => toast.classList.remove('show'), 1800);
    });
  });
  document.querySelectorAll('[data-dismiss]').forEach((button) => {
    button.addEventListener('click', () => button.closest('.overlay')?.remove());
  });
  document.querySelectorAll('.chip').forEach((chip) => {
    chip.addEventListener('click', () => chip.classList.toggle('active'));
  });
});
