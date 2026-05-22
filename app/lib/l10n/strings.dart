// Todas as strings visíveis ao usuário — PT e EN
// Acesso: kStr(isPt)['key']
Map<String, String> kStr(bool isPt) => isPt ? _pt : _en;

const _pt = {
  'question':       'Aonde vamos hoje?',
  'subtitle':       'Escolha um bairro de Los Angeles',
  'now':            'Agora',
  'tonight':        'Esta noite',
  'weekend':        'Fim de semana',
  'safety':         'Segurança',
  'traffic':        'Trânsito',
  'weather':        'Clima',
  'back':           'Voltar',
  'loading':        'Carregando...',
  'high':           'Elevado',
  'medium':         'Moderado',
  'low':            'Tranquilo',
  'congested':      'Congestionado',
  'slow':           'Lento',
  'flowing':        'Fluindo',
  'rain':           'Chuva',
  'drizzle':        'Garoa',
  'clear':          'Limpo',
  'now_label':      'Agora',
  'tonight_label':  '20h',
  'weekend_label':  'Sáb 15h',
  'guide_title':    'O que você precisa saber:',

  // Segurança
  'safe_high_pt':   'Esse horário em {area} costuma ter bastante movimento e '
      'ocorrências registradas. Prefira áreas bem iluminadas e transporte por app.',
  'safe_medium_pt': 'É um horário razoável, mas fique de olho nos arredores. '
      'Evite ruas desertas e prefira caminhar em grupo.',
  'safe_low_pt':    'Tudo tranquilo por aí nesse horário. Boa pedida pra curtir o bairro!',

  // Trânsito
  'traffic_heavy_pt':  'O trânsito tá pesado (média {speed} mph). Conta com atraso — '
      'vale considerar metrô ou app de carona.',
  'traffic_medium_pt': 'Trânsito moderado (média {speed} mph). Tudo fluindo, mas pode '
      'ter lentidão em pontos específicos.',
  'traffic_light_pt':  'Vias livres (média {speed} mph). Ótima hora pra se deslocar!',

  // Clima
  'weather_rain_pt':    'Tem chuva prevista ({prcp} mm). Leva guarda-chuva '
      'e evite ruas alagadas.',
  'weather_drizzle_pt': 'Garoa possível. Vale ficar de olho no tempo.',
  'weather_clear_pt':   'Clima limpo, {temp}°C. Agradável pra caminhar.',
};

const _en = {
  'question':       'Where are we going today?',
  'subtitle':       'Choose a neighborhood in Los Angeles',
  'now':            'Now',
  'tonight':        'Tonight',
  'weekend':        'Weekend',
  'safety':         'Safety',
  'traffic':        'Traffic',
  'weather':        'Weather',
  'back':           'Back',
  'loading':        'Loading...',
  'high':           'High',
  'medium':         'Moderate',
  'low':            'Safe',
  'congested':      'Congested',
  'slow':           'Slow',
  'flowing':        'Flowing',
  'rain':           'Rain',
  'drizzle':        'Drizzle',
  'clear':          'Clear',
  'now_label':      'Now',
  'tonight_label':  '8 PM',
  'weekend_label':  'Sat 3 PM',
  'guide_title':    'What you need to know:',

  // Safety
  'safe_high_pt':   'This time in {area} tends to have a lot of activity and reported '
      'incidents. Stick to well-lit areas and use a rideshare app.',
  'safe_medium_pt': 'It\'s a reasonable time to go, but stay aware of your surroundings. '
      'Avoid empty streets and walk in groups when possible.',
  'safe_low_pt':    'It\'s pretty calm around there at this hour. Great time to explore the neighborhood!',

  // Traffic
  'traffic_heavy_pt':  'Traffic is heavy (avg {speed} mph). Expect delays — '
      'consider the metro or a rideshare.',
  'traffic_medium_pt': 'Moderate traffic (avg {speed} mph). Things are moving, but '
      'there may be slow spots.',
  'traffic_light_pt':  'Roads are clear (avg {speed} mph). Great time to hit the road!',

  // Weather
  'weather_rain_pt':    'Rain is expected ({prcp} mm). Bring an umbrella '
      'and watch out for flooded streets.',
  'weather_drizzle_pt': 'Light drizzle possible. Keep an eye on the weather.',
  'weather_clear_pt':   'Clear skies, {temp}°C. Nice weather for a walk.',
};
