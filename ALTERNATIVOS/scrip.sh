##1.1 
#!/bin/bash
# NexoIT - Joomla (IP actual) + WordPress (IP extra) en Ubuntu Server 24.04
# Uso: sudo bash nexoit-setup.sh      (opcional: sudo IP2=192.168.129.80 bash nexoit-setup.sh)
set -e
[ "$EUID" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }
export DEBIAN_FRONTEND=noninteractive

IFACE=${IFACE:-enp0s3}
IP1=$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | head -1 | cut -d/ -f1)
IP2=${IP2:-192.168.129.59}
PREFIX=22
echo ">> Joomla: $IP1   WordPress: $IP2"

# ---------- Red: IP adicional para WordPress ----------
if ! ip -4 -o addr show "$IFACE" | grep -q "$IP2/"; then
  if ping -c1 -W1 "$IP2" >/dev/null 2>&1; then echo "ERROR: $IP2 ya está en uso. Usa otra: IP2=x.x.x.x"; exit 1; fi
  cat > /etc/netplan/99-nexoit.yaml <<EOF
network:
  version: 2
  ethernets:
    $IFACE:
      addresses: [$IP2/$PREFIX]
EOF
  chmod 600 /etc/netplan/99-nexoit.yaml
  netplan apply; sleep 3
fi

# ---------- Paquetes ----------
apt-get update -y
apt-get install -y apache2 mariadb-server php libapache2-mod-php php-mysql php-xml php-mbstring \
  php-curl php-zip php-gd php-intl unzip curl sudo
a2enmod rewrite >/dev/null

# ---------- Bases de datos (usuario/usuario) ----------
mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS joomla_nexoit CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS wp_nexoit CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'usuario'@'localhost' IDENTIFIED BY 'usuario';
GRANT ALL ON joomla_nexoit.* TO 'usuario'@'localhost';
GRANT ALL ON wp_nexoit.* TO 'usuario'@'localhost';
FLUSH PRIVILEGES;
SQL

# ---------- Contenido y diseño compartido ----------
B=/tmp/nexoit-build; mkdir -p $B

cat > $B/landing.php <<'EOF'
<section class="hero" id="inicio"><div class="wrap hero-in">
<div>
<h1>Si se rompe, lo arreglamos. Si no existe, lo programamos.</h1>
<p>NexoIT repara ordenadores y móviles, y diseña páginas web para negocios que no pueden permitirse parar.</p>
<p><a class="btn" href="#contacto">Pedir presupuesto</a><a class="btn alt" href="#servicios">Ver servicios</a></p>
</div>
<aside class="ticket" aria-label="Ejemplo de parte de reparación">
<h3>Parte de reparación #2841</h3>
<p class="dev">Portátil · pantalla rota</p>
<ol><li class="ok">Recibido</li><li class="ok">Diagnóstico</li><li class="now">Reparando</li><li>Listo para recoger</li></ol>
<p class="eta">Te avisamos por mensaje cuando esté listo.</p>
</aside></div></section>

<section id="servicios" class="wrap sec"><h2>Qué hacemos</h2><div class="grid">
<article><h3>Ordenadores</h3><p>Pantallas, baterías, discos, virus y lentitud. Diagnóstico sin coste.</p></article>
<article><h3>Móviles y tablets</h3><p>Cambio de pantalla y batería, conectores de carga y recuperación de datos.</p></article>
<article><h3>Páginas web</h3><p>Webs a medida para tu negocio, rápidas y fáciles de actualizar por ti.</p></article>
<article><h3>Soporte y mantenimiento</h3><p>Copias de seguridad, actualizaciones y ayuda cuando algo falla.</p></article>
</div></section>

<section id="proceso" class="wrap sec"><h2>Cómo trabajamos</h2><ol class="steps">
<li><b>Diagnóstico</b> Revisamos el equipo o tu idea y te explicamos qué pasa.</li>
<li><b>Presupuesto</b> Precio cerrado antes de tocar nada.</li>
<li><b>Reparación o desarrollo</b> Trabajamos y te mantenemos informado.</li>
<li><b>Entrega</b> Pruebas juntos y con garantía por escrito.</li>
</ol></section>

<section id="contacto" class="wrap sec"><h2>Cuéntanos qué necesitas</h2>
<form onsubmit="event.preventDefault();var f=this;location.href='mailto:info@nexoit.local?subject='+encodeURIComponent('Consulta de '+f.nombre.value)+'&body='+encodeURIComponent(f.mensaje.value+'\n\nTeléfono: '+f.tel.value);">
<input name="nombre" placeholder="Nombre" required><input name="tel" placeholder="Teléfono">
<textarea name="mensaje" rows="4" placeholder="¿Qué se ha roto o qué web necesitas?" required></textarea>
<button class="btn" type="submit">Enviar consulta</button></form></section>
EOF

cat > $B/base.css <<'EOF'
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.6 var(--body),system-ui,sans-serif}
h1,h2,h3{font-family:var(--head),system-ui,sans-serif;line-height:1.1;margin:0 0 .5em}
.wrap{max-width:1080px;margin:auto;padding:0 20px}
.top{background:var(--topbg);color:var(--topink)}
.top .wrap{display:flex;justify-content:space-between;align-items:center;height:64px}
.top a{color:inherit;text-decoration:none;margin-left:22px}.top a:hover{text-decoration:underline}
.top .logo{margin:0;font:800 1.5rem var(--head),sans-serif}.logo b{color:var(--acc)}
.hero{background:var(--herobg);color:var(--heroink);padding:72px 0 88px}
.hero-in{display:grid;grid-template-columns:1.3fr 1fr;gap:48px;align-items:center}
h1{font-size:clamp(2.1rem,5vw,3.5rem)}.hero p{max-width:52ch}
.btn{display:inline-block;background:var(--acc);color:var(--btnink);border:2px solid var(--acc);padding:12px 22px;border-radius:var(--r);font:700 1rem var(--body),sans-serif;text-decoration:none;margin:6px 10px 0 0;cursor:pointer}
.btn.alt{background:none;color:inherit;border-color:currentColor}
.ticket{background:var(--tbg);color:var(--tink);padding:26px;border-radius:var(--r);border-left:8px solid var(--acc);transform:rotate(1.5deg);box-shadow:0 18px 40px rgba(0,0,0,.25)}
.ticket h3{font-size:1.2rem}.ticket .dev{margin:0 0 10px;opacity:.75}
.ticket ol{list-style:none;padding:0;margin:0 0 12px}
.ticket li{padding:6px 0 6px 28px;position:relative;opacity:.6}
.ticket li:before{content:"";position:absolute;left:0;top:13px;width:14px;height:14px;border-radius:50%;border:2px solid currentColor}
.ticket .ok:before{background:#1f9d55;border-color:#1f9d55}.ticket .ok{opacity:1}
.ticket .now{opacity:1;font-weight:700}.ticket .now:before{background:var(--acc);border-color:var(--acc)}
.ticket .eta{font-size:.9rem;margin:0;opacity:.7}
.sec{padding-top:64px;padding-bottom:24px}.sec h2{font-size:2rem}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:20px}
.grid article{background:var(--card);padding:22px;border-top:4px solid var(--ink)}
.grid h3{font-size:1.2rem}.grid p{margin:0;color:var(--mut)}
.steps{counter-reset:s;list-style:none;padding:0;display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:24px}
.steps li{counter-increment:s;position:relative;padding-top:48px;color:var(--mut)}
.steps li:before{content:counter(s);position:absolute;top:0;left:0;width:36px;height:36px;border-radius:50%;background:var(--acc);color:var(--btnink);display:grid;place-items:center;font-weight:800}
.steps b{display:block;color:var(--ink);font-size:1.1rem}
form{display:grid;gap:12px;max-width:520px}
input,textarea{padding:12px;border:1px solid #b9c4cf;border-radius:var(--r);font:inherit;background:#fff}
input:focus,textarea:focus,.btn:focus-visible,a:focus-visible{outline:3px solid var(--acc);outline-offset:2px}
.foot{margin-top:64px;background:var(--topbg);color:var(--topink);padding:26px 0;text-align:center;font-size:.95rem}
@media(max-width:760px){.hero-in{grid-template-columns:1fr}.top nav a{margin-left:12px}}
EOF

# Paleta WordPress: banco de trabajo (azul tinta + ámbar)
cat > $B/wp.css <<'EOF'
:root{--bg:#f2f5f8;--ink:#0e2238;--acc:#ffb000;--mut:#52637a;--card:#fff;--btnink:#0e2238;--r:4px;
--topbg:#0e2238;--topink:#fff;--herobg:#0e2238;--heroink:#fff;--tbg:#fff;--tink:#0e2238;
--head:"Bricolage Grotesque";--body:"Hanken Grotesk"}
EOF
# Paleta Joomla: más cálida y editorial (verde petróleo + coral)
cat > $B/joomla.css <<'EOF'
:root{--bg:#fff;--ink:#12303a;--acc:#f0543c;--mut:#4d6670;--card:#eef6f4;--btnink:#fff;--r:999px;
--topbg:#fff;--topink:#12303a;--herobg:#dff0ec;--heroink:#12303a;--tbg:#12303a;--tink:#fff;
--head:"Fraunces";--body:"DM Sans"}
.top{border-bottom:1px solid #d5e4e0}.foot{background:#12303a;color:#fff}
.hero h1{font-weight:800;letter-spacing:-.02em}
.grid article{border-top:0;border-radius:24px}.btn.alt{color:#12303a}
input,textarea{border-radius:16px}
EOF

NAV='<a href="/#servicios">Servicios</a><a href="/#proceso">Proceso</a><a href="/#contacto">Contacto</a>'

# ---------- JOOMLA ----------
mkdir -p /var/www/joomla && cd /var/www/joomla
if [ ! -f configuration.php ]; then
  ZIP=$(curl -s https://api.github.com/repos/joomla/joomla-cms/releases/latest | grep -o 'https[^"]*Full_Package.zip' | head -1)
  [ -n "$ZIP" ] || { echo "No pude localizar Joomla. Revisa conexión a internet."; exit 1; }
  curl -L -o /tmp/joomla.zip "$ZIP" && unzip -q -o /tmp/joomla.zip && rm /tmp/joomla.zip
  chown -R www-data:www-data /var/www/joomla
  sudo -u www-data php installation/joomla.php install --site-name="NexoIT" \
    --admin-user="Admin NexoIT" --admin-username=usuario --admin-password='Tmp-Nexoit#2026x' \
    --admin-email=usuario@nexoit.local --db-type=mysqli --db-host=localhost \
    --db-name=joomla_nexoit --db-user=usuario --db-pass=usuario --db-prefix=jos_ --db-encryption=0 --no-interaction
  # Joomla exige 12+ caracteres en el instalador: fijamos "usuario" directamente en la BD
  HASH=$(php -r 'echo password_hash("usuario", PASSWORD_BCRYPT);')
  mysql joomla_nexoit -e "UPDATE jos_users SET password='$HASH' WHERE username='usuario';"
  rm -rf installation; cp -n htaccess.txt .htaccess
fi

T=/var/www/joomla/templates/nexoit; mkdir -p $T/css
cat > $T/templateDetails.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<extension type="template" client="site" method="upgrade">
  <name>nexoit</name><version>1.0</version><author>NexoIT</author>
  <description>Plantilla NexoIT</description>
  <files><filename>index.php</filename><filename>landing.php</filename><folder>css</folder></files>
</extension>
EOF
cp $B/landing.php $T/landing.php
cat $B/joomla.css $B/base.css > $T/css/style.css
cat > $T/index.php <<EOF
<?php
defined('_JEXEC') or die;
use Joomla\CMS\Factory;
\$menu = Factory::getApplication()->getMenu();
\$home = \$menu->getActive() == \$menu->getDefault();
?><!DOCTYPE html>
<html lang="es"><head><meta name="viewport" content="width=device-width,initial-scale=1">
<jdoc:include type="metas" />
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:wght@600;800&family=DM+Sans:wght@400;700&display=swap">
<link rel="stylesheet" href="<?php echo \$this->baseurl; ?>/templates/nexoit/css/style.css">
<jdoc:include type="styles" /><jdoc:include type="scripts" /></head><body>
<header class="top"><div class="wrap"><a class="logo" href="/">Nexo<b>IT</b></a><nav>$NAV</nav></div></header>
<?php if (\$home) : include __DIR__ . '/landing.php'; else : ?>
<main class="wrap sec"><jdoc:include type="message" /><jdoc:include type="component" /></main>
<?php endif; ?>
<footer class="foot"><div class="wrap">© NexoIT · Reparaciones y diseño web</div></footer>
</body></html>
EOF
chown -R www-data:www-data $T
cd /var/www/joomla
sudo -u www-data php cli/joomla.php extension:discover || true
sudo -u www-data php cli/joomla.php extension:discover:install || true
mysql joomla_nexoit -e "UPDATE jos_template_styles SET home='0' WHERE client_id=0; UPDATE jos_template_styles SET home='1' WHERE template='nexoit' AND client_id=0;"

# ---------- WORDPRESS ----------
curl -sL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /usr/local/bin/wp
mkdir -p /var/www/wordpress /tmp/wpcli; chown www-data:www-data /var/www/wordpress /tmp/wpcli
wpc(){ sudo -u www-data env WP_CLI_CACHE_DIR=/tmp/wpcli wp --path=/var/www/wordpress "$@"; }
if [ ! -f /var/www/wordpress/wp-config.php ]; then
  wpc core download --locale=es_ES
  wpc config create --dbname=wp_nexoit --dbuser=usuario --dbpass=usuario --locale=es_ES
  wpc core install --url="http://$IP2" --title="NexoIT" --admin_user=usuario --admin_password=usuario \
    --admin_email=usuario@nexoit.local --skip-email
fi

W=/var/www/wordpress/wp-content/themes/nexoit; mkdir -p $W
{ printf '/*\nTheme Name: NexoIT\nAuthor: NexoIT\nVersion: 1.0\n*/\n'; cat $B/wp.css $B/base.css; } > $W/style.css
cp $B/landing.php $W/landing.php
cat > $W/functions.php <<'EOF'
<?php
add_action('after_setup_theme', function(){ add_theme_support('title-tag'); });
add_action('wp_enqueue_scripts', function(){
  wp_enqueue_style('nexoit-fonts','https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@600;800&family=Hanken+Grotesk:wght@400;700&display=swap',[],null);
  wp_enqueue_style('nexoit-style', get_stylesheet_uri(), ['nexoit-fonts'], '1.0');
});
EOF
cat > $W/header.php <<EOF
<!DOCTYPE html><html <?php language_attributes(); ?>><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><?php wp_head(); ?></head>
<body <?php body_class(); ?>>
<header class="top"><div class="wrap"><a class="logo" href="<?php echo home_url('/'); ?>">Nexo<b>IT</b></a><nav>$NAV</nav></div></header>
EOF
cat > $W/footer.php <<'EOF'
<footer class="foot"><div class="wrap">© NexoIT · Reparaciones y diseño web</div></footer>
<?php wp_footer(); ?></body></html>
EOF
cat > $W/front-page.php <<'EOF'
<?php get_header(); include __DIR__ . '/landing.php'; get_footer();
EOF
cat > $W/index.php <<'EOF'
<?php get_header(); ?><main class="wrap sec"><?php while (have_posts()) : the_post(); ?>
<article><h2><?php the_title(); ?></h2><?php the_content(); ?></article><?php endwhile; ?></main><?php get_footer();
EOF
chown -R www-data:www-data $W
wpc theme activate nexoit
if [ -z "$(wpc option get page_on_front)" ] || [ "$(wpc option get page_on_front)" = "0" ]; then
  ID=$(wpc post create --post_type=page --post_title=Inicio --post_status=publish --porcelain)
  wpc option update show_on_front page; wpc option update page_on_front "$ID"
fi
wpc rewrite structure '/%postname%/' --hard >/dev/null 2>&1 || true
chown -R www-data:www-data /var/www/wordpress

# ---------- Apache ----------
cat > /etc/apache2/sites-available/000-joomla.conf <<EOF
<VirtualHost *:80>
  ServerName nexoit-joomla.local
  DocumentRoot /var/www/joomla
  <Directory /var/www/joomla>
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>
EOF
cat > /etc/apache2/sites-available/010-wordpress.conf <<EOF
<VirtualHost $IP2:80>
  ServerName nexoit-wordpress.local
  DocumentRoot /var/www/wordpress
  <Directory /var/www/wordpress>
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>
EOF
a2dissite 000-default >/dev/null 2>&1 || true
a2ensite 000-joomla 010-wordpress >/dev/null
systemctl restart apache2

cat <<EOF

=========== LISTO ===========
Joomla     : http://$IP1        Admin: http://$IP1/administrator
WordPress  : http://$IP2        Admin: http://$IP2/wp-admin
Usuario / contraseña (CMS y base de datos): usuario / usuario
=============================
EOF
#1.2
#!/bin/bash
# NexoIT v2 - se ejecuta DESPUÉS de nexoit-setup.sh
# Con correo:  sudo SMTP_USER=tucorreo@gmail.com SMTP_PASS='xxxx xxxx xxxx xxxx' bash nexoit-v2.sh
# Sin correo:  sudo bash nexoit-v2.sh   (las citas se guardan igualmente en el panel)
set -e
[ "$EUID" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }
SMTP_HOST=${SMTP_HOST:-smtp.gmail.com}; SMTP_USER=${SMTP_USER:-}; SMTP_PASS=${SMTP_PASS:-}
ADMIN_MAIL=${ADMIN_MAIL:-$SMTP_USER}
APP=/var/www/nexoit-citas; mkdir -p $APP

# ---------- Correo saliente (msmtp) ----------
if [ -n "$SMTP_USER" ]; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y msmtp msmtp-mta
  cat > /etc/msmtprc <<EOF
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account nexoit
host $SMTP_HOST
port 587
from $SMTP_USER
user $SMTP_USER
password $SMTP_PASS
account default : nexoit
EOF
  chown root:www-data /etc/msmtprc; chmod 640 /etc/msmtprc
  echo 'sendmail_path = "/usr/bin/msmtp -t"' > /etc/php/8.3/apache2/conf.d/99-nexoit-mail.ini
fi

# ---------- Base de datos de citas y pedidos ----------
mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS nexoit_citas CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL ON nexoit_citas.* TO 'usuario'@'localhost';
USE nexoit_citas;
CREATE TABLE IF NOT EXISTS citas(id INT AUTO_INCREMENT PRIMARY KEY,nombre VARCHAR(120),email VARCHAR(160),tel VARCHAR(40),
 servicio VARCHAR(160),fecha DATE,hora VARCHAR(5),notas TEXT,estado VARCHAR(20) DEFAULT 'pendiente',creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS pedidos(id INT AUTO_INCREMENT PRIMARY KEY,nombre VARCHAR(120),email VARCHAR(160),tel VARCHAR(40),
 items TEXT,total DECIMAL(9,2),estado VARCHAR(20) DEFAULT 'pendiente',creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
SQL

# ---------- App de citas/pedidos (compartida por los dos sitios) ----------
base64 -d > $APP/logo.png <<'EOF'
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
EOF

cat > $APP/config.php <<EOF
<?php
\$DB = new mysqli('localhost','usuario','usuario','nexoit_citas'); \$DB->set_charset('utf8mb4');
const ADMIN_MAIL = '$ADMIN_MAIL';
const FROM_MAIL = '${SMTP_USER:-noreply@nexoit.local}';
function h(\$s){ return htmlspecialchars((string)\$s, ENT_QUOTES, 'UTF-8'); }
function enviar(\$to, \$asunto, \$html){
  if (!\$to) return;
  \$hd = "MIME-Version: 1.0\r\nContent-Type: text/html; charset=UTF-8\r\nFrom: NexoIT <".FROM_MAIL.">\r\n";
  @mail(\$to, '=?UTF-8?B?'.base64_encode(\$asunto).'?=', '<div style="font:16px sans-serif">'.\$html.'<p>— Equipo NexoIT</p></div>', \$hd);
}
EOF

cat > $APP/api.php <<'EOF'
<?php
require __DIR__.'/config.php';
header('Content-Type: application/json');
function out($a){ echo json_encode($a); exit; }
$a = $_GET['a'] ?? '';
if ($a === 'slots') {
  $f = $_GET['f'] ?? '';
  if (!preg_match('/^\d{4}-\d\d-\d\d$/', $f)) out([]);
  $q = $DB->prepare("SELECT hora FROM citas WHERE fecha=? AND estado<>'cancelada'");
  $q->bind_param('s', $f); $q->execute();
  out(array_column($q->get_result()->fetch_all(MYSQLI_ASSOC), 'hora'));
}
$d = json_decode(file_get_contents('php://input'), true) ?: [];
$n = trim($d['nombre'] ?? ''); $e = trim($d['email'] ?? ''); $tel = trim($d['tel'] ?? '');
if (!$n || !filter_var($e, FILTER_VALIDATE_EMAIL)) out(['ok'=>false,'msg'=>'Revisa tu nombre y tu correo.']);
if ($a === 'cita') {
  $f = $d['fecha'] ?? ''; $hr = $d['hora'] ?? ''; $s = trim($d['servicio'] ?? ''); $nt = trim($d['notas'] ?? '');
  if (!preg_match('/^\d{4}-\d\d-\d\d$/', $f) || $f <= date('Y-m-d') || date('N', strtotime($f)) == 7
      || !preg_match('/^(09|1[0-9]):00$/', $hr) || $hr > '19:00')
    out(['ok'=>false,'msg'=>'Elige un día de lunes a sábado y una hora.']);
  $q = $DB->prepare("SELECT id FROM citas WHERE fecha=? AND hora=? AND estado<>'cancelada'");
  $q->bind_param('ss', $f, $hr); $q->execute();
  if ($q->get_result()->num_rows) out(['ok'=>false,'msg'=>'Esa hora acaba de ocuparse. Elige otra.']);
  $q = $DB->prepare("INSERT INTO citas(nombre,email,tel,servicio,fecha,hora,notas) VALUES(?,?,?,?,?,?,?)");
  $q->bind_param('sssssss', $n, $e, $tel, $s, $f, $hr, $nt); $q->execute();
  $fx = date('d/m/Y', strtotime($f));
  enviar($e, 'Hemos recibido tu cita en NexoIT', '<h2>Hola '.h($n).'</h2><p>Tu cita para <b>'.h($s).'</b> es el <b>'.$fx.' a las '.h($hr).'</b>. Te avisaremos cuando la confirmemos.</p>');
  enviar(ADMIN_MAIL, "Nueva cita: $n ($fx $hr)", '<p><b>'.h($n).'</b> · '.h($e).' · '.h($tel).'</p><p>'.h($s).' — '.$fx.' '.h($hr).'</p><p>'.h($nt).'</p>');
  out(['ok'=>true]);
}
if ($a === 'pedido') {
  $its = is_array($d['items'] ?? null) ? $d['items'] : []; $tot = 0; $lin = [];
  foreach ($its as $i) { $p = (float)($i['p'] ?? 0); $tot += $p; $lin[] = ['n'=>substr((string)($i['n'] ?? ''),0,60), 'p'=>$p]; }
  if (!$lin) out(['ok'=>false,'msg'=>'El carrito está vacío.']);
  $js = json_encode($lin, JSON_UNESCAPED_UNICODE);
  $q = $DB->prepare("INSERT INTO pedidos(nombre,email,tel,items,total) VALUES(?,?,?,?,?)");
  $q->bind_param('ssssd', $n, $e, $tel, $js, $tot); $q->execute();
  $ul = '<ul>'; foreach ($lin as $l) $ul .= '<li>'.h($l['n']).' — '.$l['p'].' €</li>'; $ul .= '</ul>';
  enviar($e, 'Tu reserva en NexoIT', '<h2>Gracias, '.h($n).'</h2><p>Hemos reservado:</p>'.$ul.'<p><b>Total: '.$tot.' €</b>. Te contactaremos para la entrega y el pago.</p>');
  enviar(ADMIN_MAIL, "Nuevo pedido de $n ($tot €)", '<p>'.h($n).' · '.h($e).' · '.h($tel).'</p>'.$ul);
  out(['ok'=>true]);
}
out(['ok'=>false]);
EOF

cat > $APP/admin.php <<'EOF'
<?php
session_start(); require __DIR__.'/config.php';
if (isset($_POST['u']) && $_POST['u']==='usuario' && ($_POST['p']??'')==='usuario') $_SESSION['ok']=1;
if (isset($_GET['salir'])) { session_destroy(); header('Location: admin.php'); exit; }
$css = '<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>
body{margin:0;font:15px/1.5 system-ui,sans-serif;background:#07121f;color:#e8f3ff;padding:20px}a{color:#18d6ff}
h1,h2{margin:.2em 0 .5em}table{border-collapse:collapse;width:100%}td,th{border:1px solid #1c3552;padding:6px 8px;vertical-align:top;text-align:left}
.cal td{height:92px;width:14.28%;font-size:13px}.cal b{color:#8fb0cf}.chip{display:block;margin:2px 0;padding:2px 6px;border-radius:6px;background:#0b2d6b}
.chip.confirmada{background:#065f46}.chip.cancelada{background:#7f1d1d;text-decoration:line-through}
button,input{padding:7px 12px;border-radius:8px;border:0;font:inherit}button{background:#1da1ff;color:#fff;cursor:pointer;margin:1px}
.card{background:#0d1e33;border:1px solid #1c3552;border-radius:14px;padding:16px;margin-bottom:22px;overflow-x:auto}</style>';
if (empty($_SESSION['ok'])) {
  echo $css.'<form method=post style="max-width:300px;margin:12vh auto;text-align:center"><img src="logo.png" width=90><h2>Panel NexoIT</h2>
  <p><input name=u placeholder=Usuario></p><p><input name=p type=password placeholder=Contraseña></p><button>Entrar</button></form>'; exit;
}
if (isset($_POST['id'], $_POST['est'])) {
  $id = (int)$_POST['id']; $e = in_array($_POST['est'], ['confirmada','cancelada','pendiente']) ? $_POST['est'] : 'pendiente';
  $t = ($_POST['t'] ?? '') === 'p' ? 'pedidos' : 'citas';
  $DB->query("UPDATE $t SET estado='$e' WHERE id=$id");
  if ($t === 'citas' && $e === 'confirmada' && ($r = $DB->query("SELECT * FROM citas WHERE id=$id")->fetch_assoc()))
    enviar($r['email'], 'Cita confirmada en NexoIT', '<h2>¡Confirmada, '.h($r['nombre']).'!</h2><p>Te esperamos el <b>'.date('d/m/Y', strtotime($r['fecha'])).' a las '.h($r['hora']).'</b> para '.h($r['servicio']).'.</p>');
  header('Location: '.$_SERVER['REQUEST_URI']); exit;
}
function bt($t,$id,$e,$l){ return "<form method=post style=display:inline><input type=hidden name=t value=$t><input type=hidden name=id value=$id><input type=hidden name=est value=$e><button>$l</button></form>"; }
$m = preg_match('/^\d{4}-\d\d$/', $_GET['m'] ?? '') ? $_GET['m'] : date('Y-m');
$t0 = strtotime("$m-01"); $nd = (int)date('t', $t0); $off = (int)date('N', $t0) - 1;
$MES = ['','enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
$rs = $DB->query("SELECT * FROM citas WHERE fecha LIKE '$m-%' ORDER BY fecha,hora")->fetch_all(MYSQLI_ASSOC);
$by = []; foreach ($rs as $r) $by[(int)substr($r['fecha'],8)][] = $r;
$pe = $DB->query("SELECT COUNT(*) c FROM citas WHERE estado='pendiente'")->fetch_assoc()['c'];
echo $css."<img src=logo.png height=46 align=left style='margin-right:12px'><h1>Panel NexoIT</h1><p>Citas pendientes: <b>$pe</b> · <a href='?salir=1'>Salir</a></p>";
echo '<div class=card><h2><a href="?m='.date('Y-m',strtotime("$m-01 -1 month")).'">◀</a> '.$MES[(int)date('n',$t0)].' '.date('Y',$t0).' <a href="?m='.date('Y-m',strtotime("$m-01 +1 month")).'">▶</a></h2><table class=cal><tr>';
foreach (['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'] as $dn) echo "<th>$dn</th>"; echo '</tr><tr>';
for ($i=0; $i<$off; $i++) echo '<td></td>';
for ($d=1; $d<=$nd; $d++) {
  if (($off+$d-1) % 7 == 0 && $d > 1) echo '</tr><tr>';
  echo "<td><b>$d</b>"; foreach ($by[$d] ?? [] as $r) echo '<span class="chip '.h($r['estado']).'">'.h($r['hora']).' '.h($r['nombre']).'</span>'; echo '</td>';
}
echo '</tr></table></div><div class=card><h2>Citas del mes</h2><table><tr><th>Fecha</th><th>Cliente</th><th>Servicio</th><th>Estado</th><th></th></tr>';
foreach ($rs as $r) echo '<tr><td>'.date('d/m',strtotime($r['fecha'])).' '.h($r['hora']).'</td><td>'.h($r['nombre']).'<br>'.h($r['email']).' '.h($r['tel']).'</td><td>'.h($r['servicio']).'<br><small>'.h($r['notas']).'</small></td><td>'.h($r['estado']).'</td><td>'.bt('c',$r['id'],'confirmada','Confirmar').bt('c',$r['id'],'cancelada','Cancelar').'</td></tr>';
echo '</table></div><div class=card><h2>Pedidos de la tienda</h2><table><tr><th>Cliente</th><th>Artículos</th><th>Total</th><th>Estado</th><th></th></tr>';
foreach ($DB->query("SELECT * FROM pedidos ORDER BY id DESC LIMIT 50") as $r) {
  $its = implode(', ', array_map(fn($i)=>h($i['n']), json_decode($r['items'], true) ?: []));
  echo '<tr><td>'.h($r['nombre']).'<br>'.h($r['email']).' '.h($r['tel']).'</td><td>'.$its.'</td><td>'.h($r['total']).' €</td><td>'.h($r['estado']).'</td><td>'.bt('p',$r['id'],'confirmada','Entregado').bt('p',$r['id'],'cancelada','Cancelar').'</td></tr>';
}
echo '</table></div>';
EOF
chown -R www-data:www-data $APP

cat > /etc/apache2/conf-available/nexoit-citas.conf <<'EOF'
Alias /nexoit-citas /var/www/nexoit-citas
<Directory /var/www/nexoit-citas>
  Require all granted
  DirectoryIndex admin.php
</Directory>
EOF
a2enconf nexoit-citas >/dev/null

# ---------- Nueva portada (compartida; WordPress oscuro, Joomla claro) ----------
cat > /tmp/landing2.php <<'EOF'
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Sora:wght@600;800&family=Manrope:wght@400;600;800&display=swap">
<style>
html{scroll-behavior:smooth}.top,.foot{display:none}
.nx{--bg:#07121f;--bg2:#0d1e33;--ink:#e8f3ff;--mut:#8fb0cf;--line:#1c3552;--a:#1da1ff;--a2:#18d6ff;background:var(--bg);color:var(--ink);font:16px/1.6 Manrope,sans-serif;overflow-x:hidden;transition:background .4s,color .4s}
.nx[data-t=light]{--bg:#f4f9ff;--bg2:#fff;--ink:#0b2340;--mut:#4d6a88;--line:#cfe2f3;--a:#0a6cff;--a2:#00b0e0}
.nx *{box-sizing:border-box}.nx a{color:inherit}
.nx h1,.nx h2,.nx h3{font-family:Sora,sans-serif;line-height:1.1;margin:0 0 .5em}
.nx section{max-width:1100px;margin:auto;padding:90px 20px}.nx h2{font-size:clamp(1.8rem,4vw,2.6rem)}
.bar{position:fixed;top:0;left:0;height:3px;width:0;background:linear-gradient(90deg,var(--a),var(--a2));z-index:99}
#mbtn{position:fixed;top:16px;left:16px;z-index:80;width:64px;height:64px;border-radius:50%;border:2px solid var(--line);background:var(--bg2) url(/nexoit-citas/logo.png) center/68% no-repeat;cursor:pointer;box-shadow:0 8px 30px #0006;transition:transform .3s}
#mbtn:hover{transform:rotate(-10deg) scale(1.1)}
#menu{position:fixed;top:0;left:0;height:100%;width:310px;z-index:70;background:var(--bg2);border-right:1px solid var(--line);padding:96px 20px 20px;display:flex;flex-direction:column;gap:4px;overflow:auto;transform:translateX(-105%);transition:transform .5s cubic-bezier(.7,0,.2,1)}
#menu.open{transform:none}
#menu a,#menu summary{padding:11px 14px;border-radius:12px;text-decoration:none;font-weight:800;cursor:pointer;display:block;transition:.25s}
#menu a:hover,#menu a.on,#menu summary:hover{background:linear-gradient(90deg,var(--a),var(--a2));color:#fff;padding-left:24px}
#menu details a{font-weight:600;margin-left:14px;color:var(--mut)}#menu details[open] summary{color:var(--a2)}
#menu .tg{margin-top:auto;display:flex;gap:8px}
#ov{position:fixed;inset:0;background:#0008;z-index:60;opacity:0;pointer-events:none;transition:.4s}#ov.show{opacity:1;pointer-events:auto}
.btn{display:inline-block;border:0;cursor:pointer;background:linear-gradient(90deg,var(--a),var(--a2));color:#fff;padding:13px 26px;border-radius:999px;font:800 1rem Manrope,sans-serif;text-decoration:none;margin:6px 8px 0 0;transition:transform .2s,box-shadow .2s}
.btn:hover{transform:translateY(-3px);box-shadow:0 10px 28px #1da1ff55}.btn.o{background:none;border:2px solid var(--a);color:var(--ink)}
.nx a:focus-visible,.nx button:focus-visible,.nx input:focus-visible,.nx select:focus-visible,.nx textarea:focus-visible{outline:3px solid var(--a2);outline-offset:2px}
.hero{position:relative;min-height:100vh;display:grid;place-items:center;text-align:center;padding:90px 20px;overflow:hidden;background:radial-gradient(circle at 50% 30%,var(--bg2),var(--bg))}
.hero canvas{position:absolute;inset:0;width:100%;height:100%}.hin{position:relative;max-width:760px}
.hl{width:130px;animation:fl 5s ease-in-out infinite}@keyframes fl{50%{transform:translateY(-12px)}}
.hero h1{font-size:clamp(2.2rem,6vw,4rem)}#tw{color:var(--a2)}#tw:after{content:"|";animation:bl 1s steps(1) infinite}@keyframes bl{50%{opacity:0}}
.hero p{color:var(--mut);font-size:1.15rem}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px;padding-top:0!important}
.stats div{background:var(--bg2);border:1px solid var(--line);border-radius:20px;padding:22px;text-align:center}
.stats b{display:block;font:800 2.4rem Sora,sans-serif;color:var(--a2)}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:18px}
.card{background:var(--bg2);border:1px solid var(--line);border-radius:22px;padding:24px;transition:transform .15s,border-color .3s}
.card:hover{border-color:var(--a)}.card p{color:var(--mut);margin:0}
.card details summary{cursor:pointer;font-weight:800;color:var(--a2);margin-top:12px}
.box{background:var(--bg2);border:1px solid var(--line);border-radius:24px;padding:28px}
.nx select,.nx input,.nx textarea{width:100%;padding:12px 14px;border-radius:14px;border:1px solid var(--line);background:var(--bg);color:var(--ink);font:inherit;margin:6px 0}
.row{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px}
#dr{margin-top:14px;font-size:1.15rem}#dr b{color:var(--a2)}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin:12px 0}
.chip{border:1px solid var(--line);background:var(--bg2);color:var(--ink);padding:8px 16px;border-radius:999px;cursor:pointer;font:700 .9rem Manrope,sans-serif;transition:.2s}
.chip.on,.chip:hover:not(:disabled){background:var(--a);border-color:var(--a);color:#fff}.chip:disabled{opacity:.3;cursor:not-allowed;text-decoration:line-through}
.ph{width:84px;height:158px;margin:0 auto 14px;border-radius:18px;border:3px solid #0006;position:relative;box-shadow:0 12px 24px #0005,inset 0 0 0 2px #fff3}
.ph:before{content:"";position:absolute;top:7px;left:50%;width:26px;height:6px;margin-left:-13px;border-radius:9px;background:#0007}
.ph:after{content:"";position:absolute;top:30px;left:10px;width:22px;height:22px;border-radius:50%;background:#0005}
.pr{display:flex;justify-content:space-between;align-items:center;margin-top:10px}.pr b{font:800 1.4rem Sora,sans-serif}
.tag{font-size:.8rem;color:var(--a2);font-weight:800}
#cb{position:fixed;top:22px;right:20px;z-index:50;background:var(--a);color:#fff;border:0;border-radius:999px;padding:12px 20px;font:800 1rem Manrope;cursor:pointer;box-shadow:0 8px 24px #0005}
#cd{position:fixed;top:0;right:0;width:min(400px,100%);height:100%;z-index:75;background:var(--bg2);border-left:1px solid var(--line);padding:24px;overflow:auto;transform:translateX(105%);transition:transform .45s cubic-bezier(.7,0,.2,1)}#cd.open{transform:none}
.msg{margin-top:10px;font-weight:800;color:var(--a2)}
.nx details.f{border-bottom:1px solid var(--line);padding:14px 0}.nx details.f summary{cursor:pointer;font-weight:800}.nx details.f p{color:var(--mut);margin:8px 0 0}
#up{position:fixed;bottom:84px;right:20px;width:48px;height:48px;border-radius:50%;border:0;background:var(--bg2);color:var(--ink);border:1px solid var(--line);cursor:pointer;opacity:0;pointer-events:none;transition:.3s;z-index:50}#up.show{opacity:1;pointer-events:auto}
#wa{position:fixed;bottom:20px;right:20px;z-index:50;background:#22c55e;color:#fff!important;text-decoration:none;font-weight:800;padding:13px 20px;border-radius:999px;box-shadow:0 8px 24px #0005}
.ft{text-align:center;color:var(--mut);padding:40px 20px;border-top:1px solid var(--line)}
@media(prefers-reduced-motion:reduce){.nx *{animation:none!important;transition:none!important}}
</style>
<div class="nx" data-t="__THEME__">
<div class="bar"></div>
<button id="mbtn" aria-label="Abrir menú"></button><div id="ov"></div>
<nav id="menu" aria-label="Menú principal">
 <a href="#inicio">Inicio</a>
 <details><summary>Taller</summary><a href="#servicios">Servicios</a><a href="#diagnostico">Calcula tu reparación</a></details>
 <details><summary>Tienda</summary><a href="#tienda">Móviles de segunda mano</a><a href="#" id="mc">Ver mi carrito</a></details>
 <details><summary>Contacto</summary><a href="#cita">Pedir cita</a><a href="#faq">Preguntas frecuentes</a></details>
 <div class="tg"><button class="chip" id="tt">Claro / oscuro</button><a class="chip" href="/nexoit-citas/admin.php" target="_blank">Panel</a></div>
</nav>
<button id="cb">Carrito (<span id="cn">0</span>)</button>
<aside id="cd" aria-label="Carrito"><h3>Tu reserva</h3><div id="cl"></div><p><b>Total: <span id="ct">0</span> €</b></p>
 <input id="cnm" placeholder="Nombre"><input id="cem" type="email" placeholder="Correo"><input id="ctl" placeholder="Teléfono">
 <button class="btn" id="cok">Reservar</button><button class="btn o" id="cx">Cerrar</button><div class="msg" id="cm"></div></aside>

<header class="hero" id="inicio"><canvas id="cv"></canvas><div class="hin">
 <img class="hl" src="/nexoit-citas/logo.png" alt="NexoIT">
 <h1>Reparamos <span id="tw"></span></h1>
 <p>Reparación de móviles y ordenadores, móviles de segunda mano con garantía y webs a medida. Todo en un solo sitio.</p>
 <a class="btn" href="#cita">Pedir cita</a><a class="btn o" href="#tienda">Ver tienda</a></div></header>

<section class="stats"><div><b class="cn" data-n="4800">0</b>reparaciones hechas</div><div><b class="cn" data-n="12">0</b>meses de garantía</div><div><b class="cn" data-n="24">0</b>horas de media</div><div><b class="cn" data-n="120">0</b>webs entregadas</div></section>

<section id="servicios"><h2>Qué hacemos</h2><div class="grid">
 <div class="card tilt"><h3>Móviles y tablets</h3><p>Pantallas, baterías, conectores y daños por agua.</p><details><summary>Qué incluye</summary><p>Diagnóstico gratis, pieza de calidad, 6 meses de garantía en la reparación.</p></details></div>
 <div class="card tilt"><h3>Ordenadores</h3><p>Portátiles y sobremesa: lentitud, virus, ampliaciones y piezas.</p><details><summary>Qué incluye</summary><p>Copia de tus datos, limpieza interna y revisión completa.</p></details></div>
 <div class="card tilt"><h3>Páginas web</h3><p>Webs para tu negocio, con citas, tienda y panel fácil de usar.</p><details><summary>Qué incluye</summary><p>Diseño a medida, adaptada a móvil, posicionamiento básico y formación.</p></details></div>
 <div class="card tilt"><h3>Soporte y mantenimiento</h3><p>Copias de seguridad, actualizaciones y ayuda cuando algo falla.</p><details><summary>Qué incluye</summary><p>Cuotas mensuales sin permanencia y respuesta rápida.</p></details></div></div></section>

<section id="diagnostico"><div class="box"><h2>Calcula el precio de tu reparación</h2><div class="row"><select id="dv"></select><select id="dp"></select></div><div id="dr"></div></div></section>

<section id="tienda"><h2>Móviles de segunda mano</h2><p style="color:var(--mut)">Revisados, con batería comprobada y 12 meses de garantía.</p><div class="chips" id="fl"></div><div class="grid" id="pg"></div></section>

<section id="cita"><div class="box"><h2>Pide tu cita</h2><p style="color:var(--mut)">Recibirás un correo al reservar y otro cuando la confirmemos. Atendemos de lunes a sábado.</p>
 <div class="row"><input id="fn" placeholder="Nombre"><input id="fm" type="email" placeholder="Correo electrónico"><input id="ft" placeholder="Teléfono"></div>
 <div class="row"><select id="sv"><option>Reparación de móvil</option><option>Reparación de tablet</option><option>Reparación de portátil o PC</option><option>Diseño web</option><option>Soporte y mantenimiento</option><option>Otro</option></select><input id="fe" type="date"></div>
 <div class="chips" id="hs"></div><textarea id="fo" rows="3" placeholder="Cuéntanos qué le pasa a tu equipo o qué web necesitas"></textarea>
 <button class="btn" id="fs">Reservar cita</button><div class="msg" id="fg"></div></div></section>

<section id="faq"><h2>Preguntas frecuentes</h2>
 <details class="f"><summary>¿El diagnóstico tiene coste?</summary><p>No. Revisamos tu equipo gratis y te damos un precio cerrado antes de reparar.</p></details>
 <details class="f"><summary>¿Cuánto tardáis?</summary><p>La mayoría de reparaciones de móvil se entregan en 24 a 48 horas.</p></details>
 <details class="f"><summary>¿Los móviles de segunda mano tienen garantía?</summary><p>Sí, 12 meses. Todos pasan una revisión de pantalla, batería, cámaras y conectores.</p></details>
 <details class="f"><summary>¿Hacéis webs con citas y tienda?</summary><p>Sí. Esta misma web es un ejemplo: citas con aviso por correo, tienda y panel de gestión.</p></details></section>
<div class="ft">© NexoIT · Reparaciones, tienda y diseño web</div>
<a id="wa" href="https://wa.me/34600000000" target="_blank" rel="noopener">WhatsApp</a><button id="up" aria-label="Subir">↑</button>
</div>
<script>
(function(){
const $=s=>document.querySelector(s),$$=s=>[...document.querySelectorAll(s)],nx=$('.nx');
const post=(a,d)=>fetch('/nexoit-citas/api.php?a='+a,{method:'POST',body:JSON.stringify(d)}).then(r=>r.json()).catch(()=>({ok:false,msg:'No se pudo conectar. Inténtalo de nuevo.'}));
/* menú plegable */
const mn=$('#menu'),ov=$('#ov'),cd=$('#cd');
const tog=o=>{mn.classList.toggle('open',o);ov.classList.toggle('show',o);if(!o)cd.classList.remove('open')};
$('#mbtn').onclick=()=>tog(!mn.classList.contains('open'));ov.onclick=()=>tog(false);
addEventListener('keydown',e=>e.key=='Escape'&&tog(false));
$$('#menu a[href^="#"]').forEach(a=>a.addEventListener('click',()=>{if(a.id!='mc')tog(false)}));
$('#tt').onclick=()=>{nx.dataset.t=nx.dataset.t=='dark'?'light':'dark'};
/* progreso, volver arriba, menú activo */
addEventListener('scroll',()=>{$('.bar').style.width=scrollY/(document.body.scrollHeight-innerHeight)*100+'%';$('#up').classList.toggle('show',scrollY>600)});
$('#up').onclick=()=>scrollTo({top:0});
const spy=new IntersectionObserver(es=>es.forEach(e=>{if(e.isIntersecting)$$('#menu a').forEach(a=>a.classList.toggle('on',a.getAttribute('href')=='#'+e.target.id))}),{threshold:.5});
$$('header[id],section[id]').forEach(s=>spy.observe(s));
/* máquina de escribir */
const W=['móviles','portátiles','tablets','tu idea en una web'];let wi=0,ci=0,del=0;
(function t(){const w=W[wi];$('#tw').textContent=w.slice(0,ci);
 if(!del){ci++;if(ci>w.length){del=1;ci=w.length;return setTimeout(t,1400)}}else{ci--;if(ci<0){del=0;ci=0;wi=(wi+1)%W.length}}
 setTimeout(t,del?40:90)})();
/* red de nodos que reacciona al ratón */
const cv=$('#cv'),cx=cv.getContext('2d');let P=[],mx=-999,my=-999;
const rs=()=>{cv.width=cv.offsetWidth;cv.height=cv.offsetHeight;P=Array.from({length:Math.min(90,cv.width/12)},()=>({x:Math.random()*cv.width,y:Math.random()*cv.height,vx:(Math.random()-.5)*.6,vy:(Math.random()-.5)*.6}))};
rs();addEventListener('resize',rs);
cv.parentNode.addEventListener('mousemove',e=>{const r=cv.getBoundingClientRect();mx=e.clientX-r.left;my=e.clientY-r.top});
if(!matchMedia('(prefers-reduced-motion:reduce)').matches)(function d(){cx.clearRect(0,0,cv.width,cv.height);const c=getComputedStyle(nx).getPropertyValue('--a2');cx.fillStyle=c;cx.strokeStyle=c;
 P.forEach((p,i)=>{p.x+=p.vx;p.y+=p.vy;if(p.x<0||p.x>cv.width)p.vx*=-1;if(p.y<0||p.y>cv.height)p.vy*=-1;
  cx.globalAlpha=.9;cx.beginPath();cx.arc(p.x,p.y,2.2,0,7);cx.fill();
  for(let j=i+1;j<P.length;j++){const q=P[j],dd=Math.hypot(p.x-q.x,p.y-q.y);if(dd<120){cx.globalAlpha=.5*(1-dd/120);cx.beginPath();cx.moveTo(p.x,p.y);cx.lineTo(q.x,q.y);cx.stroke()}}
  const dm=Math.hypot(p.x-mx,p.y-my);if(dm<170){cx.globalAlpha=1-dm/170;cx.beginPath();cx.moveTo(p.x,p.y);cx.lineTo(mx,my);cx.stroke()}});
 requestAnimationFrame(d)})();
/* contadores */
const co=new IntersectionObserver(es=>es.forEach(e=>{if(!e.isIntersecting)return;co.unobserve(e.target);const n=+e.target.dataset.n;let v=0;const s=setInterval(()=>{v+=Math.ceil(n/50);if(v>=n){v=n;clearInterval(s)}e.target.textContent=v.toLocaleString('es')},30)}));
$$('.cn').forEach(c=>co.observe(c));
/* tarjetas 3D */
const tilt=c=>{c.onmousemove=e=>{const r=c.getBoundingClientRect(),x=(e.clientX-r.left)/r.width-.5,y=(e.clientY-r.top)/r.height-.5;c.style.transform='perspective(700px) rotateY('+x*12+'deg) rotateX('+-y*12+'deg)'};c.onmouseleave=()=>c.style.transform=''};
$$('.tilt').forEach(tilt);
/* calculadora */
const D={'Móvil':{'Pantalla rota':[49,149],'Batería':[29,59],'No carga (conector)':[35,69],'Daños por agua':[45,119],'Lento o con fallos':[20,45]},
 'Tablet':{'Pantalla rota':[59,169],'Batería':[39,79],'No carga (conector)':[39,75],'Lenta o con fallos':[20,45]},
 'Portátil':{'Pantalla':[69,189],'Teclado':[45,99],'Lento o con virus':[30,69],'No enciende':[39,129],'Ampliar RAM o disco SSD':[49,119]}};
const dv=$('#dv'),dp=$('#dp');dv.innerHTML=Object.keys(D).map(k=>'<option>'+k+'</option>').join('');
const dr=()=>{const r=D[dv.value][dp.value];$('#dr').innerHTML='Precio estimado: <b>'+r[0]+' a '+r[1]+' €</b> · entrega en 24 a 48 h · diagnóstico gratis.<br><a class="btn" href="#cita" id="dres">Reservar esta reparación</a>';
 $('#dres').onclick=()=>{const o=document.createElement('option');o.textContent=dv.value+': '+dp.value;$('#sv').prepend(o);$('#sv').value=o.textContent}};
const dpf=()=>{dp.innerHTML=Object.keys(D[dv.value]).map(k=>'<option>'+k+'</option>').join('');dr()};
dv.onchange=dpf;dp.onchange=dr;dpf();
/* tienda */
const PR=[{n:'iPhone 12',m:'Apple',s:'128 GB',g:'Como nuevo',p:279,c:'#1da1ff,#0b2d6b'},{n:'iPhone 13',m:'Apple',s:'128 GB',g:'Muy bueno',p:349,c:'#ff7ab8,#7a1f5c'},
 {n:'Galaxy S21',m:'Samsung',s:'128 GB',g:'Muy bueno',p:229,c:'#a78bfa,#2b1b6b'},{n:'Galaxy A54',m:'Samsung',s:'128 GB',g:'Como nuevo',p:219,c:'#34d399,#065f46'},
 {n:'Redmi Note 12',m:'Xiaomi',s:'128 GB',g:'Bueno',p:129,c:'#fbbf24,#92400e'},{n:'Pixel 7',m:'Google',s:'128 GB',g:'Muy bueno',p:249,c:'#e5e7eb,#374151'}];
let cart={};try{cart=JSON.parse(localStorage.nx||'{}')}catch(e){}
const sv=()=>{try{localStorage.nx=JSON.stringify(cart)}catch(e){}};
const pgr=f=>{$('#pg').innerHTML='';PR.forEach((p,i)=>{if(f&&p.m!=f)return;const d=document.createElement('div');d.className='card tilt';
 d.innerHTML='<div class="ph" style="background:linear-gradient(160deg,'+p.c+')"></div><span class="tag">'+p.g+'</span><h3>'+p.n+'</h3><p>'+p.m+' · '+p.s+' · 12 meses de garantía</p><div class="pr"><b>'+p.p+' €</b><button class="btn" style="margin:0">'+(cart[i]?'En el carrito':'Añadir')+'</button></div>';
 d.querySelector('button').onclick=()=>{cart[i]=1;sv();cr();pgr(f);cd.classList.add('open');ov.classList.add('show')};tilt(d);$('#pg').append(d)})};
const ms=[...new Set(PR.map(p=>p.m))];
$('#fl').innerHTML=['Todos',...ms].map(m=>'<button class="chip">'+m+'</button>').join('');
$$('#fl .chip').forEach(b=>b.onclick=()=>{$$('#fl .chip').forEach(x=>x.classList.remove('on'));b.classList.add('on');pgr(b.textContent=='Todos'?'':b.textContent)});
function cr(){const k=Object.keys(cart);$('#cn').textContent=k.length;$('#ct').textContent=k.reduce((s,i)=>s+PR[i].p,0);
 $('#cl').innerHTML=k.length?k.map(i=>'<p>'+PR[i].n+' · '+PR[i].p+' € <button class="chip" data-i="'+i+'">Quitar</button></p>').join(''):'<p>Tu carrito está vacío.</p>';
 $$('#cl .chip').forEach(b=>b.onclick=()=>{delete cart[b.dataset.i];sv();cr();pgr('')})}
$('#cb').onclick=()=>{cd.classList.add('open');ov.classList.add('show')};
$('#mc').onclick=e=>{e.preventDefault();cd.classList.add('open')};$('#cx').onclick=()=>tog(false);
$('#cok').onclick=async()=>{const r=await post('pedido',{nombre:$('#cnm').value,email:$('#cem').value,tel:$('#ctl').value,items:Object.keys(cart).map(i=>({n:PR[i].n,p:PR[i].p}))});
 $('#cm').textContent=r.ok?'¡Reservado! Te hemos enviado un correo.':(r.msg||'No se pudo reservar.');if(r.ok){cart={};sv();cr();pgr('')}};
pgr('');cr();
/* citas */
const fe=$('#fe');fe.min=new Date(Date.now()+864e5).toISOString().slice(0,10);let hh='';
fe.onchange=async()=>{hh='';const hs=$('#hs');hs.innerHTML='';if(!fe.value)return;
 if(new Date(fe.value+'T12:00').getDay()==0){hs.textContent='Los domingos estamos cerrados.';return}
 let oc=[];try{oc=await fetch('/nexoit-citas/api.php?a=slots&f='+fe.value).then(r=>r.json())}catch(e){}
 for(let h=9;h<=19;h++){const t=String(h).padStart(2,'0')+':00',b=document.createElement('button');b.className='chip';b.textContent=t;b.disabled=oc.includes(t);
  b.onclick=()=>{hh=t;$$('#hs .chip').forEach(x=>x.classList.remove('on'));b.classList.add('on')};hs.append(b)}};
$('#fs').onclick=async()=>{const r=await post('cita',{nombre:$('#fn').value,email:$('#fm').value,tel:$('#ft').value,servicio:$('#sv').value,fecha:fe.value,hora:hh,notas:$('#fo').value});
 $('#fg').textContent=r.ok?'¡Cita reservada! Revisa tu correo.':(r.msg||'No se pudo reservar.');if(r.ok)fe.onchange()};
})();
</script>
EOF
sed 's/__THEME__/light/' /tmp/landing2.php > /var/www/joomla/templates/nexoit/landing.php
sed 's/__THEME__/dark/'  /tmp/landing2.php > /var/www/wordpress/wp-content/themes/nexoit/landing.php
chown www-data:www-data /var/www/joomla/templates/nexoit/landing.php /var/www/wordpress/wp-content/themes/nexoit/landing.php

# ---------- WordPress: calendario en el panel y plugins útiles ----------
mkdir -p /var/www/wordpress/wp-content/mu-plugins
cat > /var/www/wordpress/wp-content/mu-plugins/nexoit-admin.php <<'EOF'
<?php
add_action('admin_menu', function(){
  add_menu_page('Citas NexoIT','Citas NexoIT','manage_options','nexoit-citas',function(){
    echo '<iframe src="/nexoit-citas/admin.php" style="width:100%;height:88vh;border:0;margin-top:10px;border-radius:12px"></iframe>';
  },'dashicons-calendar-alt',3);
});
EOF
chown -R www-data:www-data /var/www/wordpress/wp-content/mu-plugins
mkdir -p /tmp/wpcli; chown www-data:www-data /tmp/wpcli
wpc(){ sudo -u www-data env WP_CLI_CACHE_DIR=/tmp/wpcli wp --path=/var/www/wordpress "$@"; }
wpc plugin install updraftplus wordpress-seo --activate || echo "(plugins no instalados, se pueden añadir desde el panel)"

# ---------- Joomla: calendario en el escritorio del panel ----------
mysql joomla_nexoit <<'SQL' || echo "(no se pudo añadir el módulo al panel de Joomla)"
INSERT INTO jos_modules (title,note,content,ordering,position,published,module,access,showtitle,params,client_id,language)
SELECT 'Citas NexoIT','','<iframe src="/nexoit-citas/admin.php" style="width:100%;height:85vh;border:0"></iframe>',1,'cpanel',1,'mod_custom',1,1,'{"prepare_content":"0","layout":"_:default","style":"0"}',1,'*'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM jos_modules WHERE title='Citas NexoIT');
INSERT INTO jos_modules_menu (moduleid,menuid) SELECT id,0 FROM jos_modules WHERE title='Citas NexoIT'
AND NOT EXISTS (SELECT 1 FROM jos_modules_menu mm JOIN jos_modules m ON m.id=mm.moduleid WHERE m.title='Citas NexoIT');
SQL

systemctl restart apache2
IP1=$(ip -4 -o addr show enp0s3 | awk '{print $4}' | head -1 | cut -d/ -f1)
cat <<EOF

=========== NEXOIT V2 LISTO ===========
Panel de citas y pedidos : http://<ip>/nexoit-citas/   (usuario / usuario)
En WordPress             : wp-admin > "Citas NexoIT"
En Joomla                : /administrator > escritorio (módulo "Citas NexoIT")
Correo: $([ -n "$SMTP_USER" ] && echo "configurado con $SMTP_USER" || echo "SIN configurar (las citas se guardan igual en el panel)")
=======================================
EOF
#1.3
#!/bin/bash
# NexoIT v2.1 - formulario de cita: Nombre, Correo, Motivo, Descripción (+ día y hora)
# Ejecutar DESPUÉS de nexoit-v2.sh:  sudo bash nexoit-v2.1.sh
[ "$EUID" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }
set -e

python3 - <<'PY'
import re, os
LAND = os.environ.get('LANDS', '/var/www/joomla/templates/nexoit/landing.php:/var/www/wordpress/wp-content/themes/nexoit/landing.php').split(':')
API = os.environ.get('API', '/var/www/nexoit-citas/api.php')
for p in LAND:
    s = open(p).read()
    if 'id="ft"' not in s:
        print('ya aplicado:', p); continue
    sel = re.search(r'<select id="sv">.*?</select>', s, re.S).group(0)
    new = ('<div class="row"><label>Nombre<input id="fn" placeholder="Tu nombre"></label>'
           '<label>Correo electrónico<input id="fm" type="email" placeholder="tucorreo@ejemplo.com"></label></div>\n'
           '<label>Motivo de la cita' + sel + '</label>\n'
           '<label>Descripción<textarea id="fo" rows="4" placeholder="Cuéntanos qué le pasa a tu equipo o qué web necesitas"></textarea></label>\n'
           '<label>Día<input id="fe" type="date"></label><div class="chips" id="hs"></div>')
    s = re.sub(r'<div class="row"><input id="fn".*?</textarea>', lambda m: new, s, flags=re.S)
    s = s.replace("tel:$('#ft').value", "tel:''")
    s = s.replace('.msg{margin-top:10px', '.nx label{display:block;font-weight:800;font-size:.9rem;margin-top:10px}.msg{margin-top:10px', 1)
    open(p, 'w').write(s); print('actualizado:', p)
a = open(API).read()
if '$nt = trim($d[\'notas\'] ?? \'\'); if' not in a:
    a = a.replace("$nt = trim($d['notas'] ?? '');", "$nt = trim($d['notas'] ?? ''); if (!$s || !$nt) out(['ok'=>false,'msg'=>'Indica el motivo y una breve descripción.']);", 1)
    open(API, 'w').write(a); print('actualizado:', API)
PY
chown www-data:www-data /var/www/joomla/templates/nexoit/landing.php /var/www/wordpress/wp-content/themes/nexoit/landing.php /var/www/nexoit-citas/api.php 2>/dev/null || true
echo "Listo. Recarga la web con Ctrl+F5."