/* Consentement aux cookies de pearl-inc.app (toutes les pages).
   Le pixel de conversion de X (Twitter) dépose des cookies publicitaires : il ne se charge
   qu'après « Accepter » (CNIL). Refuser est aussi simple qu'accepter ; le choix est gardé
   6 mois sur l'appareil, puis redemandé. Un lien [data-consent-open] rouvre la bannière.
   Une page de conversion le dit avec <body data-x-event="tw-rh65t-…"> (voir sendPageEvent).
   Pas de bannière pour Vercel Web Analytics : il ne dépose aucun cookie. */
(function(){
  // Page ouverte depuis l'app iOS (?app=1, gardé pour la visite) : ni bannière ni pixel,
  // l'app ne piste pas (App Store 5.1.2, pas de demande ATT).
  var fromApp=/[?&]app=1(&|$)/.test(location.search);
  try{if(fromApp)sessionStorage.setItem('pearl-from-app','1');else fromApp=sessionStorage.getItem('pearl-from-app')==='1';}catch(e){}
  if(fromApp){
    var hide=document.createElement('style');hide.textContent='[data-consent-open]{display:none}';document.head.appendChild(hide);
    return;
  }

  // Pages d'aide et légales (celles qu'ouvre le build 4 de l'app, sans ?app=1) : la bannière ne s'ouvre
  // pas d'elle-même, seulement par le lien « Cookies ». Le pixel n'y vient qu'avec un accord déjà donné.
  var quietPage=/^\/(en\/)?(support|confidentialite|conditions|mentions-legales|privacy|terms|legal-notice)(\/|$)/.test(location.pathname);

  var KEY='pearl-consent-v1';
  var MAX_AGE=1000*60*60*24*182; // 6 mois

  var TEXT={
    fr:{
      msg:'Pearl Inc. aimerait utiliser un cookie de X (Twitter) pour savoir quelles annonces t’ont amené ici. Rien n’est déposé sans ton accord.',
      more:'En savoir plus',href:'/confidentialite/',
      refuse:'Refuser',accept:'Accepter',label:'Cookies'
    },
    en:{
      msg:'Pearl Inc. would like to use a cookie from X (Twitter) to see which ads brought you here. Nothing is set without your consent.',
      more:'Learn more',href:'/en/privacy/',
      refuse:'Decline',accept:'Accept',label:'Cookies'
    }
  };

  function lang(){
    var l=(window.PearlI18n&&window.PearlI18n.lang)||document.documentElement.lang||'fr';
    return /^fr/i.test(l)?'fr':'en';
  }

  function readChoice(){
    try{
      var c=JSON.parse(localStorage.getItem(KEY)||'null');
      if(c&&(c.ads===true||c.ads===false)&&Date.now()-c.at<MAX_AGE)return c.ads;
    }catch(e){}
    return null;
  }
  function saveChoice(ads){
    try{localStorage.setItem(KEY,JSON.stringify({ads:ads,at:Date.now()}));}catch(e){}
  }

  var pixelLoaded=false;
  function loadXPixel(){
    if(pixelLoaded)return;pixelLoaded=true;
    // X conversion tracking base code
    !function(e,t,n,s,u,a){e.twq||(s=e.twq=function(){s.exe?s.exe.apply(s,arguments):s.queue.push(arguments);
    },s.version='1.1',s.queue=[],u=t.createElement(n),u.async=!0,u.src='https://static.ads-twitter.com/uwt.js',
    a=t.getElementsByTagName(n)[0],a.parentNode.insertBefore(u,a))}(window,document,'script');
    twq('config','rh65t');
    // End X conversion tracking base code
    sendPageEvent();
  }

  // Événement de conversion de la page (<body data-x-event="tw-rh65t-…">, ex. /merci/ = inscription).
  // Une fois par visite : recharger la page ne compte pas une deuxième inscription.
  function sendPageEvent(){
    var id=document.body&&document.body.getAttribute('data-x-event');
    if(!id)return;
    try{if(sessionStorage.getItem('pearl-x-event:'+id))return;sessionStorage.setItem('pearl-x-event:'+id,'1');}catch(e){}
    // X conversion tracking event code
    twq('event', id, {});
    // End X conversion tracking event code
  }

  var CSS='.pc-banner{position:fixed;z-index:1000;left:12px;right:12px;bottom:calc(env(safe-area-inset-bottom,0px) + 12px);max-width:560px;margin:0 auto;'
    +'background:rgba(255,255,255,.96);-webkit-backdrop-filter:saturate(180%) blur(20px);backdrop-filter:saturate(180%) blur(20px);'
    +'color:#1d1d1f;border:1px solid rgba(0,0,0,.08);border-radius:18px;box-shadow:0 10px 40px rgba(0,0,0,.14);padding:16px 18px;'
    +'font:14px/1.5 "Inter",-apple-system,"SF Pro Text",system-ui,sans-serif;-webkit-font-smoothing:antialiased;text-align:left}'
    +'.pc-banner p{margin:0 0 12px;font-size:14px}'
    +'.pc-banner a{color:#0071e3}'
    +'.pc-row{display:flex;gap:10px}'
    +'.pc-row button{flex:1;font:inherit;font-weight:600;font-size:15px;border:0;border-radius:999px;padding:10px 14px;cursor:pointer;background:#1d1d1f;color:#fff}'
    +'.pc-row button:focus-visible{outline:2px solid #0071e3;outline-offset:2px}';

  var banner=null;
  function render(){
    if(!banner)return;
    var t=TEXT[lang()];
    banner.setAttribute('aria-label',t.label);
    banner.innerHTML='<p>'+t.msg+' <a href="'+t.href+'">'+t.more+'</a></p>'
      +'<div class="pc-row"><button type="button" data-choice="0">'+t.refuse+'</button>'
      +'<button type="button" data-choice="1">'+t.accept+'</button></div>';
  }
  function open(){
    if(banner)return;
    if(!document.getElementById('pc-style')){
      var s=document.createElement('style');s.id='pc-style';s.textContent=CSS;document.head.appendChild(s);
    }
    banner=document.createElement('div');
    banner.className='pc-banner';banner.setAttribute('role','dialog');
    render();
    banner.addEventListener('click',function(e){
      var b=e.target.closest('[data-choice]');if(!b)return;
      var ads=b.getAttribute('data-choice')==='1';
      var wasLoaded=pixelLoaded;
      saveChoice(ads);close();
      if(ads)loadXPixel();
      else if(wasLoaded)location.reload(); // retrait de l'accord : on recharge sans le pixel
    });
    document.body.appendChild(banner);
  }
  function close(){if(banner){banner.remove();banner=null;}}

  if(window.PearlI18n&&window.PearlI18n.onChange)window.PearlI18n.onChange(render);
  document.addEventListener('click',function(e){
    var a=e.target.closest&&e.target.closest('[data-consent-open]');
    if(a){e.preventDefault();open();}
  });

  var choice=readChoice();
  if(choice===true)loadXPixel();
  else if(choice===null&&!quietPage)open();
})();
