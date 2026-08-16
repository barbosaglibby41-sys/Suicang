const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const glow = document.querySelector('.cursor-glow');
window.addEventListener('pointermove', (event) => {
  if (glow && !reduced) {
    glow.animate({left: `${event.clientX}px`, top: `${event.clientY}px`}, {duration: 900, fill: 'forwards', easing: 'ease-out'});
  }
});
const nav = document.querySelector('.nav');
window.addEventListener('scroll', () => nav?.classList.toggle('scrolled', window.scrollY > 30), {passive: true});
const observer = new IntersectionObserver((entries) => entries.forEach((entry) => {
  if (entry.isIntersecting) entry.target.classList.add('visible');
}), {threshold: .12});
document.querySelectorAll('.reveal').forEach((element) => observer.observe(element));
const canvas = document.querySelector('#particles');
if (canvas && !reduced) {
  const ctx = canvas.getContext('2d');
  let width, height, dots;
  const resize = () => { width = canvas.width = canvas.offsetWidth * devicePixelRatio; height = canvas.height = canvas.offsetHeight * devicePixelRatio; ctx.scale(devicePixelRatio, devicePixelRatio); dots = Array.from({length: Math.min(90, Math.floor(innerWidth / 16))}, () => ({x: Math.random()*canvas.offsetWidth, y: Math.random()*canvas.offsetHeight, r: Math.random()*1.3+.2, vx:(Math.random()-.5)*.12, vy:(Math.random()-.5)*.12, a:Math.random()*.5+.1})); };
  resize(); window.addEventListener('resize', resize);
  const draw = () => { ctx.clearRect(0,0,canvas.offsetWidth,canvas.offsetHeight); dots?.forEach((d) => { d.x += d.vx; d.y += d.vy; if(d.x<0)d.x=canvas.offsetWidth;if(d.x>canvas.offsetWidth)d.x=0;if(d.y<0)d.y=canvas.offsetHeight;if(d.y>canvas.offsetHeight)d.y=0; ctx.beginPath();ctx.arc(d.x,d.y,d.r,0,Math.PI*2);ctx.fillStyle=`rgba(177,218,255,${d.a})`;ctx.fill(); }); requestAnimationFrame(draw); };
  draw();
}
