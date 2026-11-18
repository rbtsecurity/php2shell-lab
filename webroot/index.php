<?php
// RBT Security - PHP2Shell authorized security research lab.
header('X-Lab: RBT-Security-php2shell');

$php      = PHP_VERSION;
$sapi     = PHP_SAPI;
$uname    = php_uname('s') . ' ' . php_uname('m');
$upload   = ini_get('session.upload_progress.enabled');
$memlimit = ini_get('memory_limit');
$postmax  = ini_get('post_max_size');
$display  = ini_get('display_errors');

$up   = filter_var($upload, FILTER_VALIDATE_BOOLEAN) || $upload === 'On';
$disp = filter_var($display, FILTER_VALIDATE_BOOLEAN) || $display === 'On';

// PHP2Shell floors: 8.5.12 / 8.4.27 / 8.3.36 / 8.2.35
function php2shell_unpatched(int $id): bool {
    if ($id >= 80500) return $id < 80512;
    if ($id >= 80400) return $id < 80427;
    if ($id >= 80300) return $id < 80336;
    if ($id >= 80200) return $id < 80235;
    return false;
}

$vuln = php2shell_unpatched(PHP_VERSION_ID) && $up && $disp;

if (($_GET['probe'] ?? '') === '1') {
    header('Content-Type: text/plain');
    echo "OK\n";
    exit;
}

function h($value) { return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8'); }

$badgeClass = $vuln ? 'armed' : 'patched';
$badgeText  = $vuln ? 'ARMED' : 'PATCHED';
$patchNote  = $vuln
    ? 'Patch floor: 8.5.12 / 8.4.27 / 8.3.36 / 8.2.35'
    : 'This build meets the published patch floor for this branch.';
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#071b35">
<title>RBT Security PHP2Shell Lab</title>
<style>
:root {
  color-scheme: light;
  --navy:#071b35; --navy2:#0c2d52; --blue:#1769aa;
  --cyan:#36b9d8; --ink:#17283d; --muted:#66788c;
  --line:#e2eaf1; --paper:#f4f7fa; --white:#fff;
  --green:#087f5b; --red:#b42332; --amber:#b54708;
}
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.6 Inter,ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif}
a{color:inherit;text-decoration:none}
.wrap{width:min(1120px,calc(100% - 40px));margin:auto}
.topbar{background:var(--navy);color:#d9e6f3;border-bottom:1px solid #24415f}
.topinner{min-height:76px;display:flex;align-items:center;justify-content:space-between;gap:20px}
.brand{display:flex;align-items:center;gap:14px}
.brand img{display:block;width:56px;height:56px;border-radius:2px;object-fit:contain;flex-shrink:0}
.brandfallback{font-weight:800;letter-spacing:.08em;color:white}
.topnote{font-size:12px;color:#b9cadb;letter-spacing:.08em;text-transform:uppercase}
.hero{background:linear-gradient(115deg,var(--navy),#103b65 72%,#145779);color:white;padding:64px 0 72px;position:relative;overflow:hidden}
.hero:after{content:"";position:absolute;width:440px;height:440px;border:1px solid #ffffff18;border-radius:50%;right:-90px;top:-220px;box-shadow:0 0 0 55px #ffffff08,0 0 0 110px #ffffff05}
.hero-content{position:relative;z-index:1;max-width:820px}
.eyebrow{color:#7ee0ef;font-size:12px;font-weight:750;letter-spacing:.16em;text-transform:uppercase}
.hero-title-row{display:flex;flex-wrap:wrap;align-items:center;gap:14px 18px;margin:16px 0 14px}
h1{font-size:clamp(34px,5.5vw,56px);line-height:1.05;letter-spacing:-.04em;margin:0}
.badge{display:inline-flex;align-items:center;gap:8px;padding:8px 14px;border-radius:99px;font-size:12px;font-weight:800;letter-spacing:.08em}
.badge:before{content:"";width:8px;height:8px;border-radius:50%;background:currentColor}
.badge.armed{color:#0b7a4b;background:#e6f7ef;border:1px solid #b6e5cb}
.badge.patched{color:#0b5f8a;background:#e7f4fb;border:1px solid #b9daf0}
.lead{max-width:700px;color:#d3e2ef;font-size:17px;margin:0}
main{padding:0 0 64px}
.panel{background:white;border:1px solid var(--line);border-radius:16px;box-shadow:0 14px 40px #15395b12;margin-top:-28px;position:relative;z-index:2;overflow:hidden}
.panel-pad{padding:26px 28px}
.panel h2{margin:0 0 6px;font-size:18px;color:var(--navy)}
.panel .sub{margin:0 0 18px;color:var(--muted);font-size:13px}
.cve-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}
.cve{border:1px solid var(--line);border-radius:12px;padding:16px 18px;background:#fbfcfe}
.cve .id{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:13px;font-weight:700;color:var(--navy);margin-bottom:6px}
.cve p{margin:0;color:var(--muted);font-size:13px;line-height:1.45}
.runtime{margin-top:22px}
.table{width:100%;border-collapse:collapse}
.table th,.table td{text-align:left;padding:12px 10px;border-bottom:1px solid var(--line);vertical-align:top}
.table th{width:42%;color:var(--muted);font-size:12px;font-weight:650;text-transform:uppercase;letter-spacing:.04em}
.table td{font-size:14px;font-weight:650;overflow-wrap:anywhere}
.table tr:last-child th,.table tr:last-child td{border-bottom:0}
.note{margin-top:14px;padding:12px 14px;border-radius:10px;background:#edf7fc;border:1px solid #d4eaf5;color:#456477;font-size:13px}
.foot-notes{display:grid;grid-template-columns:1.1fr .9fr;gap:16px;margin-top:22px}
.card{background:white;border:1px solid var(--line);border-radius:14px;padding:20px 22px}
.card strong{display:block;color:var(--navy);margin-bottom:6px}
.card p{margin:0;color:var(--muted);font-size:13px}
footer{border-top:1px solid var(--line);padding:22px 0;color:var(--muted);font-size:12px}
.footinner{display:flex;justify-content:space-between;gap:15px;flex-wrap:wrap}
@media(max-width:720px){
  .wrap{width:min(100% - 28px,1120px)}
  .brand img{width:44px;height:44px}
  .cve-grid,.foot-notes{grid-template-columns:1fr}
  .panel-pad{padding:20px}
}
</style>
</head>
<body>
<header class="topbar">
  <div class="wrap topinner">
    <a class="brand" href="/" aria-label="RBT Security">
      <img src="/logo-colored.png" alt="RBT Security" width="56" height="56"
           onerror="this.style.display='none';this.nextElementSibling.style.display='block'">
      <span class="brandfallback" style="display:none">RBT SECURITY</span>
    </a>
    <div class="topnote">Application security research</div>
  </div>
</header>

<section class="hero">
  <div class="wrap hero-content">
    <div class="eyebrow">RBT Security · Research environment</div>
    <div class="hero-title-row">
      <h1>RBT Security PHP2Shell Lab</h1>
      <span class="badge <?= h($badgeClass) ?>"><?= h($badgeText) ?></span>
    </div>
    <p class="lead">Authorized research target for CVE-2026-109618 / CVE-2026-109619 (session.upload_progress). Isolated Docker lab for defenders and instructors.</p>
  </div>
</section>

<main class="wrap">
  <section class="panel">
    <div class="panel-pad">
      <h2>Scope</h2>
      <p class="sub">Issues under study live in php-src, not in a WordPress plugin or this status page.</p>
      <div class="cve-grid">
        <article class="cve">
          <div class="id">CVE-2026-109618</div>
          <p>OOM bailout during multipart / upload_progress can leave session state half-initialized (heap UAF class).</p>
        </article>
        <article class="cve">
          <div class="id">CVE-2026-109619</div>
          <p>Stale session globals can survive into a later request on the same worker (use-after-free reclaim class).</p>
        </article>
      </div>

      <div class="runtime">
        <h2>Runtime</h2>
        <p class="sub">Live values from this container</p>
        <table class="table">
          <tr><th>PHP</th><td><?= h($php) ?></td></tr>
          <tr><th>SAPI</th><td><?= h($sapi) ?></td></tr>
          <tr><th>upload_progress</th><td><?= h($upload ?: 'Off') ?></td></tr>
          <tr><th>memory_limit</th><td><?= h($memlimit) ?></td></tr>
          <tr><th>Host</th><td><?= h($uname) ?></td></tr>
        </table>
        <div class="note"><?= h($patchNote) ?></div>
      </div>
    </div>
  </section>

  <div class="foot-notes">
    <div class="card">
      <strong>Upgrade note</strong>
      <p>Change the lab image to a patched tag (for example php:8.4.27-apache), rebuild, and confirm this page shows PATCHED.</p>
    </div>
    <div class="card">
      <strong>Network</strong>
      <p>Port 8105 is bound on localhost by default. Firewall the host if you open it for a private classroom network. Do not expose this lab to the public internet.</p>
    </div>
  </div>
</main>

<footer>
  <div class="wrap footinner">
    <span>&copy; <?= date('Y') ?> RBT Security · PHP2Shell Lab</span>
    <span>Defender research · Isolated environment</span>
  </div>
</footer>
</body>
</html>
