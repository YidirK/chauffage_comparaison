
clc; clear; close all;

% ── 1. PRIX DE L'ÉNERGIE (à modifier ici selon votre région) ─────────
PRIX_ELEC_DZD_KWH  = 9.0;    % Prix électricité        (DZD/kWh)
PRIX_GAZ_DZD_M3    = 21.6;   % Prix gaz naturel        (DZD/m³)
PRIX_CHARBON_DZD_KG = 70.0;  % Prix charbon            (DZD/kg)

% ── 2. SAISIE DES PARAMÈTRES VIA BOÎTE DE DIALOGUE ──────────────────
prompt = {
    'Volume d''eau (litres) :'
    'Température initiale (°C) :'
    'Température cible (°C) :'
};
titre_dlg   = 'Paramètres de simulation';
valeurs_def = {'10', '20', '50'};
dims        = [1 45];

reponse = inputdlg(prompt, titre_dlg, dims, valeurs_def);

if isempty(reponse)
    disp('Simulation annulée.');
    return;
end

vol_L = str2double(reponse{1});
T_ini = str2double(reponse{2});
T_fin = str2double(reponse{3});

% Vérifications basiques
if isnan(vol_L) || isnan(T_ini) || isnan(T_fin)
    errordlg('Veuillez entrer des valeurs numériques valides.', 'Erreur');
    return;
end
if T_fin <= T_ini
    errordlg('La température cible doit être supérieure à la température initiale.', 'Erreur');
    return;
end
if vol_L <= 0
    errordlg('Le volume doit être positif.', 'Erreur');
    return;
end

% ── 3. CONSTANTES ET DONNÉES DES MODES ──────────────────────────────
C_EAU      = 4186;          % Capacité thermique massique J/(kg·K)
masse_eau  = vol_L * 1.0;   % 1 L d'eau ≈ 1 kg
delta_T    = T_fin - T_ini;

% Données de chaque mode de chauffage
%        Nom                   Rendement  PCI(kWh/u)  Unité  Prix(DZD/u)              CO2(kg/kWh)  Couleur RGB
modes = {
    'Induction',               0.90,      1.00,       'kWh', PRIX_ELEC_DZD_KWH,       0.05,        [29  158 117]/255
    'Résistance électrique',   0.60,      1.00,       'kWh', PRIX_ELEC_DZD_KWH,       0.05,        [55  138 221]/255
    'Gaz naturel',             0.55,      10.55,      'm³',  PRIX_GAZ_DZD_M3,         0.20,        [239 159  39]/255
    'Charbon',                 0.35,      8.14,       'kg',  PRIX_CHARBON_DZD_KG,     0.34,        [136 135 128]/255
};

n = size(modes, 1);

% ── 4. CALCULS ───────────────────────────────────────────────────────
E_ideale_J   = masse_eau * C_EAU * delta_T;
E_ideale_kWh = E_ideale_J / 3.6e6;

noms        = cell(n,1);
rendements  = zeros(n,1);
energies    = zeros(n,1);
consomm     = zeros(n,1);
couts       = zeros(n,1);
emissions   = zeros(n,1);
couleurs    = zeros(n,3);
unites      = cell(n,1);

for i = 1:n
    noms{i}       = modes{i,1};
    rend          = modes{i,2};
    pci           = modes{i,3};
    unites{i}     = modes{i,4};
    prix_unite    = modes{i,5};
    co2_factor    = modes{i,6};
    couleurs(i,:) = modes{i,7};

    rendements(i) = rend * 100;
    energies(i)   = E_ideale_kWh / rend;
    consomm(i)    = energies(i) / pci;
    couts(i)      = consomm(i) * prix_unite;   % coût réel = quantité × prix unitaire
    emissions(i)  = energies(i) * co2_factor;
end

% ── 5. AFFICHAGE CONSOLE ─────────────────────────────────────────────
fprintf('\n%s\n', repmat('=', 1, 65));
fprintf('  COMPARAISON DES MODES DE CHAUFFAGE\n');
fprintf('%s\n', repmat('=', 1, 65));
fprintf('  Volume d''eau    : %.0f litres\n', vol_L);
fprintf('  Température     : %.0f°C  →  %.0f°C  (ΔT = %.0f°C)\n', T_ini, T_fin, delta_T);
fprintf('  Énergie idéale  : %.4f kWh  (Q = m·c·ΔT)\n', E_ideale_kWh);
fprintf('  Prix électricité : %.1f DZD/kWh\n', PRIX_ELEC_DZD_KWH);
fprintf('  Prix gaz naturel : %.1f DZD/m³\n',  PRIX_GAZ_DZD_M3);
fprintf('  Prix charbon     : %.1f DZD/kg\n',  PRIX_CHARBON_DZD_KG);
fprintf('%s\n', repmat('-', 1, 65));
fprintf('%-25s %10s %12s %12s %12s\n', 'Mode', 'Rendement', 'Énergie', 'Consom.', 'Coût(DZD)');
fprintf('%s\n', repmat('-', 1, 65));
for i = 1:n
    fprintf('%-25s %9.0f%%  %9.3f kWh  %7.3f %-3s  %10.1f\n', ...
        noms{i}, rendements(i), energies(i), consomm(i), unites{i}, couts(i));
end
fprintf('%s\n', repmat('=', 1, 65));
economie = (energies(2) - energies(1)) / energies(2) * 100;
fprintf('  → Économie induction vs résistance : %.1f %%\n', economie);
fprintf('  → Énergie économisée               : %.3f kWh\n', energies(2) - energies(1));
fprintf('%s\n\n', repmat('=', 1, 65));

% ── 5. GRAPHIQUES ────────────────────────────────────────────────────
fig = figure('Name', 'Comparaison des modes de chauffage', ...
             'NumberTitle', 'off', ...
             'Color', [0.98 0.98 0.97], ...
             'Position', [80 60 1280 860]);

titre_fig = sprintf('Comparaison énergétique — %.0f L d''eau  %.0f°C → %.0f°C   |   Élec: %.1f DZD/kWh   Gaz: %.1f DZD/m³   Charbon: %.1f DZD/kg', ...
                    vol_L, T_ini, T_fin, PRIX_ELEC_DZD_KWH, PRIX_GAZ_DZD_M3, PRIX_CHARBON_DZD_KG);
sgtitle(titre_fig, 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.17 0.17 0.16]);

tl = tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'loose');

% ── Graphe 1 : Énergie consommée (occupe 2 colonnes) ─────────────────
nexttile(1, [1 2]);
b1 = bar(energies, 0.55, 'FaceColor', 'flat');
b1.CData = couleurs;
b1.EdgeColor = 'white';
b1.LineWidth = 1.5;
set(gca, 'XTickLabel', noms, 'FontSize', 9, 'Color', [0.97 0.97 0.96], ...
    'Box', 'off', 'GridColor', 'white', 'YGrid', 'on');
ylabel('Énergie consommée (kWh)', 'FontSize', 10);
title('Énergie totale consommée par mode de chauffage', 'FontSize', 11, 'FontWeight', 'normal');
% Ligne énergie idéale
yline(E_ideale_kWh, '--', sprintf('Énergie idéale (%.3f kWh)', E_ideale_kWh), ...
      'Color', [0.85 0.35 0.19], 'LineWidth', 1.4, 'FontSize', 8, ...
      'LabelHorizontalAlignment', 'right');
% Étiquettes sur les barres
for i = 1:n
    ratio = energies(i) / energies(1);
    if ratio > 1
        lbl = sprintf('%.3f kWh\n(×%.1f)', energies(i), ratio);
    else
        lbl = sprintf('%.3f kWh', energies(i));
    end
    text(i, energies(i) + max(energies)*0.01, lbl, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
         'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.17 0.17 0.16]);
end

% ── Graphe 2 : Rendement (barres horizontales) ───────────────────────
nexttile(3);
b2 = barh(rendements, 0.5, 'FaceColor', 'flat');
b2.CData = couleurs;
b2.EdgeColor = 'white';
b2.LineWidth = 1.2;
set(gca, 'YTickLabel', noms, 'FontSize', 9, 'Color', [0.97 0.97 0.96], ...
    'Box', 'off', 'XGrid', 'on', 'GridColor', 'white');
xlim([0 110]);
xlabel('Rendement thermique (%)', 'FontSize', 10);
title('Rendement thermique', 'FontSize', 11, 'FontWeight', 'normal');
for i = 1:n
    text(rendements(i) + 1, i, sprintf('%.0f%%', rendements(i)), ...
         'VerticalAlignment', 'middle', 'FontSize', 9, 'FontWeight', 'bold');
end

% ── Graphe 3 : Coûts (camembert) ─────────────────────────────────────
nexttile(4);
p = pie(couts);
for i = 1:n
    p(2*i-1).FaceColor = couleurs(i,:);
    p(2*i-1).EdgeColor = 'white';
    p(2*i-1).LineWidth = 1.5;
    p(2*i).FontSize    = 9;
end
title('Répartition des coûts estimés', 'FontSize', 11, 'FontWeight', 'normal');
legend_labels = arrayfun(@(i) sprintf('%s  (%.0f DZD)', noms{i}, couts(i)), ...
                         1:n, 'UniformOutput', false);
legend(legend_labels, 'Location', 'southoutside', 'FontSize', 8, ...
       'NumColumns', 2, 'Box', 'off');

% ── Graphe 4 : Émissions CO₂ ─────────────────────────────────────────
nexttile(5);
b4 = bar(emissions, 0.55, 'FaceColor', 'flat');
b4.CData = couleurs;
b4.EdgeColor = 'white';
b4.LineWidth = 1.5;
set(gca, 'XTickLabel', noms, 'FontSize', 9, 'Color', [0.97 0.97 0.96], ...
    'Box', 'off', 'YGrid', 'on', 'GridColor', 'white');
ylabel('Émissions CO₂ (kg)', 'FontSize', 10);
title('Émissions de CO₂ estimées', 'FontSize', 11, 'FontWeight', 'normal');
for i = 1:n
    text(i, emissions(i) + max(emissions)*0.01, sprintf('%.3f kg', emissions(i)), ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
         'FontSize', 9, 'FontWeight', 'bold');
end

% ── Graphe 5 : Tableau récapitulatif ─────────────────────────────────
nexttile(6);
axis off;
col_headers = {'Mode', 'Rendement', 'Énergie (kWh)', 'Coût (DZD)'};
table_data  = cell(n, 4);
for i = 1:n
    table_data{i,1} = noms{i};
    table_data{i,2} = sprintf('%.0f %%', rendements(i));
    table_data{i,3} = sprintf('%.3f', energies(i));
    table_data{i,4} = sprintf('%.0f', couts(i));
end

% Utilisation de uitable pour le tableau
pos_ax = get(gca, 'Position');

uit = uitable(fig, ...
    'Data',               table_data, ...
    'ColumnName',         col_headers, ...
    'RowName',            {}, ...
    'Units',              'normalized', ...
    'Position',           pos_ax, ...
    'FontSize',           9, ...
    'ColumnWidth',        {140, 75, 100, 85});

title(axes('Position', pos_ax, 'Visible','off'), ...
      'Récapitulatif', 'FontSize', 11, 'FontWeight', 'normal', ...
      'Units', 'normalized', 'Position', [0.5 1.04 0]);

% ── 6. SAUVEGARDE ────────────────────────────────────────────────────
nom_fichier = sprintf('chauffage_%dL_%dC_%dC.png', vol_L, T_ini, T_fin);
exportgraphics(fig, nom_fichier, 'Resolution', 150);
fprintf('  Graphique enregistré : %s\n\n', nom_fichier);