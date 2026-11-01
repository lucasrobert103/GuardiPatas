#!/usr/bin/env python3
"""Termos de Uso, Política de Privacidade (LGPD), direitos do titular e guia para responsáveis.

Fonte única dos textos legais do GuardiPatas (português, inglês e espanhol). Gera:
    data/legal.json             -> lido pela tela "Termos e privacidade" do jogo
    docs/termos.md              -> Termos de Uso (três idiomas)
    docs/privacidade.md         -> Política de Privacidade (três idiomas)
    docs/site/*.html            -> páginas prontas para publicar (link da Play Console)

    python3 tools/make_legal.py

Ao mudar um texto que altera direitos ou obrigações, aumente VERSION: o jogo mostra de novo
o aviso "Atualizamos os termos" para quem aceitou a versão anterior.
"""
import html, json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

VERSION = "1.0"
UPDATED = "2026-11-01"
DEVELOPER = "RetroNexa"
SITE = "retronexa.com.br"
EMAIL = "contato@retronexa.com.br"
APP = "GuardiPatas"
PAGES = {"privacy": "https://retronexa.com.br/guardipatas/privacidade", "terms": "https://retronexa.com.br/guardipatas/termos"}

LANGS = ["pt", "en", "es"]
DATE = {"pt": "01/11/2026", "en": "November 1, 2026", "es": "1 de noviembre de 2026"}


def t(pt, en, es):
    return {"pt": pt, "en": en, "es": es}


def sec(title, *paragraphs):
    return {"h": title, "p": list(paragraphs)}


# --------------------------------------------------------------------------- Termos de Uso
TERMS = {
    "id": "terms",
    "title": t("Termos de Uso", "Terms of Use", "Términos de Uso"),
    "summary": t(
        "Regras simples para usar o GuardiPatas: o jogo é seu para se divertir, as moedas são de mentirinha e qualquer compra com dinheiro de verdade passa pelo Google Play, com um adulto.",
        "Simple rules for using GuardiPatas: the game is yours to enjoy, coins are make-believe and any real-money purchase goes through Google Play, with an adult.",
        "Reglas sencillas para usar GuardiPatas: el juego es tuyo para divertirte, las monedas son de mentirijillas y cualquier compra con dinero real pasa por Google Play, con un adulto."),
    "sections": [
        sec(t("1. Aceitação", "1. Acceptance", "1. Aceptación"),
            t("Ao baixar, instalar ou usar o GuardiPatas, você concorda com estes Termos de Uso e com a Política de Privacidade. Se não concordar, não use o aplicativo e desinstale-o do seu aparelho.",
              "By downloading, installing or using GuardiPatas, you agree to these Terms of Use and to the Privacy Policy. If you do not agree, do not use the app and uninstall it from your device.",
              "Al descargar, instalar o usar GuardiPatas, aceptas estos Términos de Uso y la Política de Privacidad. Si no estás de acuerdo, no uses la aplicación y desinstálala de tu dispositivo."),
            t("Crianças e adolescentes devem usar o jogo com o conhecimento de um pai, mãe ou responsável legal, que aceita estes termos em nome deles.",
              "Children and teenagers should use the game with the knowledge of a parent or legal guardian, who accepts these terms on their behalf.",
              "Los niños y adolescentes deben usar el juego con el conocimiento de su padre, madre o tutor legal, que acepta estos términos en su nombre.")),
        sec(t("2. Quem somos", "2. Who we are", "2. Quiénes somos"),
            t("O GuardiPatas é desenvolvido e publicado pela RetroNexa (retronexa.com.br). Fale com a gente pelo e-mail %s." % EMAIL,
              "GuardiPatas is developed and published by RetroNexa (retronexa.com.br). Contact us at %s." % EMAIL,
              "GuardiPatas es desarrollado y publicado por RetroNexa (retronexa.com.br). Escríbenos a %s." % EMAIL)),
        sec(t("3. Licença de uso", "3. License", "3. Licencia de uso"),
            t("A RetroNexa concede a você uma licença pessoal, gratuita, limitada, não exclusiva, intransferível e revogável para usar o jogo em aparelhos que você possui ou controla, para fins não comerciais.",
              "RetroNexa grants you a personal, free, limited, non-exclusive, non-transferable and revocable license to use the game on devices you own or control, for non-commercial purposes.",
              "RetroNexa te concede una licencia personal, gratuita, limitada, no exclusiva, intransferible y revocable para usar el juego en dispositivos que posees o controlas, con fines no comerciales."),
            t("Não é permitido: vender, alugar ou redistribuir o aplicativo; publicar versões modificadas; burlar compras, a barreira para responsáveis ou outras proteções; nem usar o jogo para qualquer finalidade ilegal. Engenharia reversa só é permitida nos limites que a lei autoriza.",
              "You may not: sell, rent or redistribute the app; publish modified versions; bypass purchases, the parental gate or other protections; or use the game for any unlawful purpose. Reverse engineering is only allowed to the extent permitted by law.",
              "No está permitido: vender, alquilar o redistribuir la aplicación; publicar versiones modificadas; eludir las compras, la barrera para adultos u otras protecciones; ni usar el juego con fines ilegales. La ingeniería inversa solo se permite en los límites que autoriza la ley.")),
        sec(t("4. Propriedade intelectual", "4. Intellectual property", "4. Propiedad intelectual"),
            t("Personagens, desenhos, músicas, sons, fases, textos, a marca GuardiPatas e a marca RetroNexa pertencem à RetroNexa ou aos seus licenciantes e são protegidos por lei. Estes termos não transferem a você nenhum desses direitos.",
              "Characters, artwork, music, sounds, levels, texts, the GuardiPatas brand and the RetroNexa brand belong to RetroNexa or its licensors and are protected by law. These terms do not transfer any of those rights to you.",
              "Los personajes, dibujos, música, sonidos, niveles, textos, la marca GuardiPatas y la marca RetroNexa pertenecen a RetroNexa o a sus licenciantes y están protegidos por la ley. Estos términos no te transfieren ninguno de esos derechos.")),
        sec(t("5. Suas criações e fotos", "5. Your creations and photos", "5. Tus creaciones y fotos"),
            t("As fases criadas no editor, as pinturas do Ateliê e as fotos do Álbum (capturas da tela do próprio jogo) ficam apenas no seu aparelho. O GuardiPatas não publica, não envia e não compartilha esse conteúdo com ninguém.",
              "Levels made in the editor, Studio paintings and Album photos (screenshots of the game itself) stay only on your device. GuardiPatas does not publish, upload or share that content with anyone.",
              "Los niveles creados en el editor, las pinturas del Taller y las fotos del Álbum (capturas de la pantalla del propio juego) quedan solo en tu dispositivo. GuardiPatas no publica, no envía ni comparte ese contenido con nadie.")),
        sec(t("6. Moedas e itens virtuais", "6. Coins and virtual items", "6. Monedas y objetos virtuales"),
            t("Moedas, dicas, petiscos, acessórios, efeitos e bichinhos são itens virtuais do jogo. Eles não têm valor em dinheiro, não podem ser trocados por dinheiro ou bens reais, nem transferidos para outra pessoa.",
              "Coins, hints, treats, accessories, effects and pets are virtual in-game items. They have no cash value and cannot be exchanged for money or real goods, or transferred to another person.",
              "Las monedas, pistas, golosinas, accesorios, efectos y mascotas son objetos virtuales del juego. No tienen valor monetario, no pueden cambiarse por dinero ni bienes reales, ni transferirse a otra persona."),
            t("O progresso fica salvo no aparelho. Desinstalar o app, limpar os dados do app ou usar \"Apagar progresso\" nos Ajustes remove os itens e não pode ser desfeito.",
              "Progress is saved on the device. Uninstalling the app, clearing the app's data or using \"Erase progress\" in Settings removes the items and cannot be undone.",
              "El progreso se guarda en el dispositivo. Desinstalar la aplicación, borrar sus datos o usar \"Borrar progreso\" en Ajustes elimina los objetos y no se puede deshacer.")),
        sec(t("7. Compras com dinheiro real", "7. Real-money purchases", "7. Compras con dinero real"),
            t("O jogo pode ser terminado sem gastar nada. Quando houver compras opcionais com dinheiro real, elas são feitas exclusivamente pelo sistema de pagamentos do Google Play, com o preço final (incluindo impostos aplicáveis) mostrado pelo Google antes da confirmação. A RetroNexa não recebe dados do seu cartão ou forma de pagamento.",
              "The game can be completed without spending anything. When optional real-money purchases are available, they are made exclusively through Google Play's payment system, with the final price (including applicable taxes) shown by Google before you confirm. RetroNexa never receives your card or payment details.",
              "El juego se puede terminar sin gastar nada. Cuando haya compras opcionales con dinero real, se realizan exclusivamente mediante el sistema de pagos de Google Play, que muestra el precio final (con los impuestos aplicables) antes de confirmar. RetroNexa no recibe los datos de tu tarjeta ni de tu forma de pago."),
            t("Antes de qualquer compra com dinheiro real, o jogo pede que um adulto resolva uma conta (barreira para responsáveis). Os responsáveis também podem exigir senha para compras nas configurações do Google Play ou no Family Link.",
              "Before any real-money purchase, the game asks an adult to solve a math question (parental gate). Parents can also require a password for purchases in Google Play settings or in Family Link.",
              "Antes de cualquier compra con dinero real, el juego pide a un adulto que resuelva una cuenta (barrera para adultos). Los padres también pueden exigir contraseña para las compras en los ajustes de Google Play o en Family Link."),
            t("Pedidos de reembolso seguem as regras do Google Play e podem ser feitos pelo próprio Google Play. Se precisar de ajuda, escreva para %s. Nada nestes termos limita os direitos que o Código de Defesa do Consumidor garante a você." % EMAIL,
              "Refund requests follow Google Play's rules and can be made through Google Play itself. If you need help, write to %s. Nothing in these terms limits your statutory consumer rights." % EMAIL,
              "Las solicitudes de reembolso siguen las reglas de Google Play y se pueden hacer desde Google Play. Si necesitas ayuda, escribe a %s. Nada en estos términos limita tus derechos legales como consumidor." % EMAIL)),
        sec(t("8. Sem anúncios e sem conversas", "8. No ads and no chat", "8. Sin anuncios y sin chat"),
            t("O GuardiPatas não exibe anúncios, não tem chat, não tem perfis, não abre links externos e não conecta você a outras pessoas.",
              "GuardiPatas does not show ads, has no chat or profiles, does not open external links and does not connect you to other people.",
              "GuardiPatas no muestra anuncios, no tiene chat ni perfiles, no abre enlaces externos y no te conecta con otras personas.")),
        sec(t("9. Atualizações e disponibilidade", "9. Updates and availability", "9. Actualizaciones y disponibilidad"),
            t("Podemos atualizar o jogo para corrigir erros, ajustar a dificuldade, mudar fases ou incluir novidades. Fazemos o possível para que tudo funcione bem, mas não garantimos que o jogo esteja livre de falhas ou disponível em todos os aparelhos.",
              "We may update the game to fix bugs, tune difficulty, change levels or add new content. We do our best to keep everything working, but we do not guarantee that the game is error-free or available on every device.",
              "Podemos actualizar el juego para corregir errores, ajustar la dificultad, cambiar niveles o añadir novedades. Hacemos lo posible para que todo funcione bien, pero no garantizamos que el juego esté libre de fallos o disponible en todos los dispositivos.")),
        sec(t("10. Uso saudável", "10. Healthy play", "10. Juego saludable"),
            t("Faça pausas e jogue em um lugar seguro. Nos Ajustes você pode reduzir os movimentos da tela, aumentar o texto, usar filtros para daltonismo e desligar a vibração e os sons.",
              "Take breaks and play somewhere safe. In Settings you can reduce screen motion, enlarge text, use color-blind filters and turn off vibration and sounds.",
              "Haz pausas y juega en un lugar seguro. En Ajustes puedes reducir el movimiento de la pantalla, agrandar el texto, usar filtros para daltonismo y apagar la vibración y los sonidos.")),
        sec(t("11. Responsabilidade", "11. Liability", "11. Responsabilidad"),
            t("Na medida permitida pela lei, a RetroNexa não responde por perdas de progresso causadas por desinstalação, troca ou defeito do aparelho, nem por uso do jogo em desacordo com estes termos. Esta cláusula não afasta nenhum direito previsto no Código de Defesa do Consumidor.",
              "To the extent permitted by law, RetroNexa is not liable for loss of progress caused by uninstalling, replacing or a fault in the device, or for use of the game contrary to these terms. This clause does not exclude any mandatory consumer right.",
              "En la medida que lo permita la ley, RetroNexa no responde por la pérdida de progreso causada por desinstalar, cambiar o averiarse el dispositivo, ni por el uso del juego en contra de estos términos. Esta cláusula no excluye ningún derecho obligatorio del consumidor.")),
        sec(t("12. Mudanças nestes termos", "12. Changes to these terms", "12. Cambios en estos términos"),
            t("Se mudarmos estes termos de forma importante, avisaremos dentro do jogo antes de você continuar. A data e a versão ficam no fim desta página. Continuar usando o jogo depois do aviso significa que você concorda com a nova versão.",
              "If we change these terms in a meaningful way, we will let you know inside the game before you continue. The date and version are shown at the end of this page. Continuing to use the game after the notice means you accept the new version.",
              "Si cambiamos estos términos de forma importante, te avisaremos dentro del juego antes de continuar. La fecha y la versión aparecen al final de esta página. Seguir usando el juego después del aviso significa que aceptas la nueva versión.")),
        sec(t("13. Lei aplicável", "13. Governing law", "13. Ley aplicable"),
            t("Estes termos seguem as leis da República Federativa do Brasil. Fica eleito o foro do domicílio do consumidor para resolver qualquer questão.",
              "These terms are governed by the laws of the Federative Republic of Brazil. Any dispute will be handled by the courts of the consumer's place of residence, without prejudice to mandatory rights in your country.",
              "Estos términos se rigen por las leyes de la República Federativa de Brasil. Cualquier cuestión se resolverá en los tribunales del domicilio del consumidor, sin perjuicio de los derechos obligatorios de tu país.")),
    ],
}

# --------------------------------------------------------------------------- Privacidade
PRIVACY = {
    "id": "privacy",
    "title": t("Política de Privacidade", "Privacy Policy", "Política de Privacidad"),
    "summary": t(
        "Resumo: o GuardiPatas não coleta dados pessoais. Não tem conta, anúncios, rastreamento, análise de uso nem SDKs de terceiros. Tudo o que o jogo guarda fica só no seu aparelho.",
        "Summary: GuardiPatas does not collect personal data. There are no accounts, ads, tracking, analytics or third-party SDKs. Everything the game saves stays only on your device.",
        "Resumen: GuardiPatas no recopila datos personales. No tiene cuentas, anuncios, rastreo, analíticas ni SDK de terceros. Todo lo que el juego guarda se queda solo en tu dispositivo."),
    "sections": [
        sec(t("1. Quem cuida dos seus dados", "1. Who is responsible", "1. Quién es responsable"),
            t("A RetroNexa, desenvolvedora do GuardiPatas, é a controladora para os fins da Lei Geral de Proteção de Dados (LGPD, Lei nº 13.709/2018). Canal de privacidade e do encarregado: %s." % EMAIL,
              "RetroNexa, the developer of GuardiPatas, is the controller under Brazil's General Data Protection Law (LGPD, Law No. 13,709/2018) and, where applicable, the GDPR. Privacy and data-protection contact: %s." % EMAIL,
              "RetroNexa, desarrolladora de GuardiPatas, es la responsable a efectos de la Ley General de Protección de Datos de Brasil (LGPD, Ley n.º 13.709/2018) y, cuando corresponda, del RGPD. Contacto de privacidad y protección de datos: %s." % EMAIL)),
        sec(t("2. O que fica salvo no seu aparelho", "2. What is saved on your device", "2. Qué se guarda en tu dispositivo"),
            t("Para o jogo funcionar, ele guarda no armazenamento privado do app: fases vencidas e estrelas, moedas e dicas, itens e acessórios, conquistas e missões, recordes do Modo Infinito, cuidados da Casinha, ajustes (som, idioma, acessibilidade, dificuldade), fases criadas no editor, pinturas do Ateliê e fotos do Álbum, e a versão dos termos aceita.",
              "To work, the game saves in the app's private storage: levels cleared and stars, coins and hints, items and accessories, achievements and missions, Infinite Mode records, Little House care, settings (sound, language, accessibility, difficulty), levels made in the editor, Studio paintings and Album photos, and the version of the terms you accepted.",
              "Para funcionar, el juego guarda en el almacenamiento privado de la aplicación: niveles superados y estrellas, monedas y pistas, objetos y accesorios, logros y misiones, récords del Modo Infinito, cuidados de la Casita, ajustes (sonido, idioma, accesibilidad, dificultad), niveles creados en el editor, pinturas del Taller y fotos del Álbum, y la versión de los términos aceptada."),
            t("Essas informações não identificam você, não saem do aparelho e não são enviadas para a RetroNexa nem para ninguém. O backup automático do Android para este app está desligado.",
              "This information does not identify you, does not leave the device and is not sent to RetroNexa or anyone else. Android automatic backup is turned off for this app.",
              "Esta información no te identifica, no sale del dispositivo y no se envía a RetroNexa ni a nadie. La copia de seguridad automática de Android está desactivada para esta aplicación.")),
        sec(t("3. O que não coletamos", "3. What we do not collect", "3. Qué no recopilamos"),
            t("Não pedimos nem coletamos nome, e-mail, telefone, idade, localização, contatos, fotos ou arquivos da galeria, câmera, microfone, identificador de publicidade, identificadores do aparelho, histórico de uso, dados de análise ou relatórios de falhas.",
              "We do not ask for or collect name, email, phone number, age, location, contacts, gallery photos or files, camera, microphone, advertising ID, device identifiers, usage history, analytics or crash reports.",
              "No pedimos ni recopilamos nombre, correo, teléfono, edad, ubicación, contactos, fotos o archivos de la galería, cámara, micrófono, identificador de publicidad, identificadores del dispositivo, historial de uso, analíticas ni informes de fallos."),
            t("O jogo não tem anúncios, não usa SDKs de terceiros para publicidade ou análise, não faz rastreamento entre apps e nunca vende ou aluga dados.",
              "The game has no ads, uses no third-party advertising or analytics SDKs, does no cross-app tracking and never sells or rents data.",
              "El juego no tiene anuncios, no usa SDK de terceros de publicidad ni analíticas, no hace rastreo entre aplicaciones y nunca vende ni alquila datos.")),
        sec(t("4. Permissões do Android", "4. Android permissions", "4. Permisos de Android"),
            t("O app pede apenas a permissão de vibração, usada para dar um toque de resposta no jogo. Ela pode ser desligada em Ajustes > Vibração. Nenhuma outra permissão sensível é usada.",
              "The app only requests the vibration permission, used for haptic feedback in the game. You can turn it off in Settings > Vibration. No other sensitive permission is used.",
              "La aplicación solo solicita el permiso de vibración, que se usa para dar una respuesta táctil en el juego. Se puede apagar en Ajustes > Vibración. No se usa ningún otro permiso sensible.")),
        sec(t("5. Compras pelo Google Play", "5. Google Play purchases", "5. Compras en Google Play"),
            t("Se você fizer uma compra com dinheiro real, o pagamento é processado pelo Google, conforme a Política de Privacidade do Google. A RetroNexa não recebe nome, e-mail nem dados de cartão.",
              "If you make a real-money purchase, payment is processed by Google under Google's Privacy Policy. RetroNexa does not receive your name, email or card details.",
              "Si haces una compra con dinero real, el pago lo procesa Google según la Política de Privacidad de Google. RetroNexa no recibe tu nombre, correo ni datos de tarjeta."),
            t("Para entregar o item, o app recebe do Google uma confirmação da compra (produto, número do pedido e código de verificação). Quando as compras reais estiverem ativas, essa confirmação é enviada a um servidor da RetroNexa apenas para checar com o Google se a compra é verdadeira, evitar fraudes e tratar reembolsos. Base legal: execução de contrato e cumprimento de obrigação legal (LGPD, art. 7º, V e II). Guardamos esse registro somente pelo tempo exigido para comprovar a compra e cumprir obrigações legais e fiscais.",
              "To deliver the item, the app receives a purchase confirmation from Google (product, order number and verification token). When real purchases are active, this confirmation is sent to a RetroNexa server only to check with Google that the purchase is genuine, prevent fraud and handle refunds. Legal basis: performance of a contract and compliance with legal obligations (LGPD art. 7, V and II). We keep this record only as long as required to prove the purchase and meet legal and tax obligations.",
              "Para entregar el objeto, la aplicación recibe de Google una confirmación de la compra (producto, número de pedido y código de verificación). Cuando las compras reales estén activas, esa confirmación se envía a un servidor de RetroNexa solo para comprobar con Google que la compra es auténtica, evitar fraudes y gestionar reembolsos. Base legal: ejecución de contrato y cumplimiento de obligaciones legales (LGPD, art. 7, V y II). Conservamos ese registro solo el tiempo necesario para acreditar la compra y cumplir obligaciones legales y fiscales.")),
        sec(t("6. Crianças", "6. Children", "6. Niños"),
            t("O GuardiPatas foi feito para toda a família, inclusive crianças. Seguimos o princípio do melhor interesse da criança (LGPD, art. 14), as regras do programa Famílias do Google Play e a lei COPPA dos Estados Unidos: não coletamos dados de crianças, não há anúncios, chat, links externos ou redes sociais, e compras com dinheiro real exigem a barreira para responsáveis.",
              "GuardiPatas is made for the whole family, including children. We follow the best interests of the child principle (LGPD art. 14), Google Play's Families policies and the US COPPA law: we do not collect children's data, there are no ads, chat, external links or social networks, and real-money purchases require the parental gate.",
              "GuardiPatas está hecho para toda la familia, incluidos los niños. Seguimos el principio del interés superior del niño (LGPD, art. 14), las políticas de Familias de Google Play y la ley COPPA de Estados Unidos: no recopilamos datos de niños, no hay anuncios, chat, enlaces externos ni redes sociales, y las compras con dinero real exigen la barrera para adultos.")),
        sec(t("7. Compartilhamento", "7. Sharing", "7. Compartir datos"),
            t("Não compartilhamos dados com terceiros. A única exceção é o próprio Google, que processa os pagamentos feitos pelo Google Play. Não há transferência internacional de dados além do que o Google realiza para processar essas compras.",
              "We do not share data with third parties. The only exception is Google itself, which processes payments made through Google Play. There is no international data transfer beyond what Google performs to process those purchases.",
              "No compartimos datos con terceros. La única excepción es el propio Google, que procesa los pagos hechos en Google Play. No hay transferencia internacional de datos más allá de la que Google realiza para procesar esas compras.")),
        sec(t("8. Segurança", "8. Security", "8. Seguridad"),
            t("O progresso fica no armazenamento privado do app, protegido pelo próprio Android. O jogo salva de forma cuidadosa para evitar perdas. Recomendamos manter o aparelho com bloqueio de tela.",
              "Progress is kept in the app's private storage, protected by Android itself. The game saves carefully to avoid losses. We recommend keeping a screen lock on your device.",
              "El progreso se guarda en el almacenamiento privado de la aplicación, protegido por el propio Android. El juego guarda con cuidado para evitar pérdidas. Recomendamos tener el bloqueo de pantalla activado.")),
        sec(t("9. Quanto tempo guardamos e como apagar", "9. Retention and deletion", "9. Conservación y borrado"),
            t("Os dados do jogo ficam no aparelho até você apagá-los. Você pode apagar tudo a qualquer momento em Ajustes > Apagar progresso, limpando os dados do app nas configurações do Android ou desinstalando o jogo. Não há conta para excluir, porque não criamos contas.",
              "Game data stays on the device until you delete it. You can erase everything at any time in Settings > Erase progress, by clearing the app's data in Android settings or by uninstalling the game. There is no account to delete because we do not create accounts.",
              "Los datos del juego se quedan en el dispositivo hasta que los borres. Puedes borrarlo todo en cualquier momento en Ajustes > Borrar progreso, borrando los datos de la aplicación en los ajustes de Android o desinstalando el juego. No hay cuenta que eliminar porque no creamos cuentas.")),
        sec(t("10. Seus direitos", "10. Your rights", "10. Tus derechos"),
            t("Pela LGPD (art. 18) você tem direito a confirmação e acesso, correção, anonimização, bloqueio ou eliminação, portabilidade, informação sobre compartilhamento e revogação do consentimento. Como os dados ficam sob seu controle no aparelho, a maioria desses direitos pode ser exercida direto no jogo. Para qualquer pedido, escreva para %s; responderemos em até 15 dias. Você também pode reclamar à Autoridade Nacional de Proteção de Dados (ANPD), em gov.br/anpd." % EMAIL,
              "Under the LGPD (art. 18) and, where applicable, the GDPR, you have the right to confirmation and access, correction, anonymization, restriction or deletion, portability, information about sharing and withdrawal of consent. Because the data stays under your control on the device, most of these rights can be exercised directly in the game. For any request, write to %s; we will reply within 15 days. You may also complain to Brazil's data protection authority (ANPD, gov.br/anpd) or your local authority." % EMAIL,
              "Según la LGPD (art. 18) y, cuando corresponda, el RGPD, tienes derecho a confirmación y acceso, rectificación, anonimización, bloqueo o eliminación, portabilidad, información sobre el intercambio de datos y revocación del consentimiento. Como los datos quedan bajo tu control en el dispositivo, la mayoría de estos derechos se pueden ejercer directamente en el juego. Para cualquier solicitud, escribe a %s; responderemos en un máximo de 15 días. También puedes reclamar ante la autoridad de protección de datos de Brasil (ANPD, gov.br/anpd) o la de tu país." % EMAIL)),
        sec(t("11. Mudanças nesta política", "11. Changes to this policy", "11. Cambios en esta política"),
            t("Se esta política mudar, a nova versão aparecerá no jogo e na página %s, com a data de atualização. Mudanças importantes serão avisadas dentro do jogo." % PAGES["privacy"],
              "If this policy changes, the new version will appear in the game and at %s, with the update date. Important changes will be announced inside the game." % PAGES["privacy"],
              "Si esta política cambia, la nueva versión aparecerá en el juego y en %s, con la fecha de actualización. Los cambios importantes se avisarán dentro del juego." % PAGES["privacy"])),
    ],
}

# --------------------------------------------------------------------------- Direitos (LGPD)
RIGHTS = {
    "id": "rights",
    "title": t("Seus direitos (LGPD)", "Your rights (LGPD)", "Tus derechos (LGPD)"),
    "summary": t(
        "Os dados do GuardiPatas são seus e ficam com você. Veja como exercer cada direito sem precisar falar com ninguém.",
        "GuardiPatas data is yours and stays with you. Here is how to exercise each right without having to ask anyone.",
        "Los datos de GuardiPatas son tuyos y se quedan contigo. Así puedes ejercer cada derecho sin tener que pedírselo a nadie."),
    "live": True,   # o jogo mostra aqui o resumo do que está salvo agora
    "sections": [
        sec(t("Confirmar e acessar", "Confirm and access", "Confirmar y acceder"),
            t("O quadro acima mostra tudo o que o jogo guarda agora neste aparelho. Nada disso está em servidores.",
              "The box above shows everything the game keeps on this device right now. None of it is on servers.",
              "El cuadro de arriba muestra todo lo que el juego guarda ahora en este dispositivo. Nada de eso está en servidores.")),
        sec(t("Corrigir", "Correct", "Rectificar"),
            t("Ajustes como idioma, som, acessibilidade e dificuldade podem ser mudados a qualquer momento nos Ajustes.",
              "Settings such as language, sound, accessibility and difficulty can be changed at any time in Settings.",
              "Los ajustes como idioma, sonido, accesibilidad y dificultad se pueden cambiar en cualquier momento en Ajustes.")),
        sec(t("Eliminar", "Delete", "Eliminar"),
            t("Use Ajustes > Apagar progresso para eliminar fases, moedas, itens, fotos do Álbum e fases do editor. Para remover também os ajustes, limpe os dados do app nas configurações do Android ou desinstale o jogo.",
              "Use Settings > Erase progress to delete levels, coins, items, Album photos and editor levels. To remove settings too, clear the app's data in Android settings or uninstall the game.",
              "Usa Ajustes > Borrar progreso para eliminar niveles, monedas, objetos, fotos del Álbum y niveles del editor. Para quitar también los ajustes, borra los datos de la aplicación en los ajustes de Android o desinstala el juego.")),
        sec(t("Revogar o aceite", "Withdraw acceptance", "Revocar la aceptación"),
            t("Você pode deixar de concordar com os termos a qualquer momento: basta parar de usar e desinstalar o jogo.",
              "You can stop agreeing to the terms at any time: just stop using and uninstall the game.",
              "Puedes dejar de aceptar los términos en cualquier momento: basta con dejar de usar y desinstalar el juego.")),
        sec(t("Falar com a RetroNexa", "Contact RetroNexa", "Hablar con RetroNexa"),
            t("Dúvidas, pedidos ou reclamações sobre privacidade: %s. Respondemos em até 15 dias. Você também pode procurar a ANPD (gov.br/anpd)." % EMAIL,
              "Privacy questions, requests or complaints: %s. We reply within 15 days. You can also contact Brazil's ANPD (gov.br/anpd) or your local data protection authority." % EMAIL,
              "Dudas, solicitudes o reclamaciones sobre privacidad: %s. Respondemos en un máximo de 15 días. También puedes acudir a la ANPD de Brasil (gov.br/anpd) o a la autoridad de tu país." % EMAIL)),
    ],
}

# --------------------------------------------------------------------------- Responsáveis
PARENTS = {
    "id": "parents",
    "title": t("Para pais e responsáveis", "For parents", "Para padres y tutores"),
    "summary": t(
        "O GuardiPatas foi pensado para crianças jogarem com segurança. Veja o que o jogo faz e o que ele nunca faz.",
        "GuardiPatas was designed so children can play safely. Here is what the game does and what it never does.",
        "GuardiPatas se pensó para que los niños jueguen con seguridad. Esto es lo que hace el juego y lo que nunca hace."),
    "sections": [
        sec(t("O que o jogo nunca faz", "What the game never does", "Lo que el juego nunca hace"),
            t("Não mostra anúncios, não tem chat nem perfis, não pede nome, e-mail ou idade, não abre links externos, não usa câmera, microfone ou localização e não coleta dados.",
              "It does not show ads, has no chat or profiles, does not ask for name, email or age, does not open external links, does not use the camera, microphone or location, and does not collect data.",
              "No muestra anuncios, no tiene chat ni perfiles, no pide nombre, correo ni edad, no abre enlaces externos, no usa la cámara, el micrófono ni la ubicación, y no recopila datos.")),
        sec(t("Compras", "Purchases", "Compras"),
            t("As moedas do jogo são ganhas jogando. Compras com dinheiro real são opcionais, passam pelo Google Play e só aparecem depois que um adulto resolve uma conta. Para mais proteção, ative \"Exigir autenticação para compras\" no Google Play ou use o Google Family Link.",
              "In-game coins are earned by playing. Real-money purchases are optional, go through Google Play and only appear after an adult solves a math question. For extra protection, turn on \"Require authentication for purchases\" in Google Play or use Google Family Link.",
              "Las monedas del juego se ganan jugando. Las compras con dinero real son opcionales, pasan por Google Play y solo aparecen después de que un adulto resuelva una cuenta. Para más protección, activa \"Pedir autenticación para las compras\" en Google Play o usa Google Family Link.")),
        sec(t("Conforto e acessibilidade", "Comfort and accessibility", "Comodidad y accesibilidad"),
            t("Nos Ajustes há opções para reduzir movimento, texto grande, destaque dos insetos, filtros para daltonismo, volume e vibração. O jogo pausa sozinho quando o app é minimizado.",
              "Settings include reduced motion, large text, insect highlighting, color-blind filters, volume and vibration. The game pauses automatically when the app is minimized.",
              "En Ajustes hay opciones para reducir el movimiento, texto grande, resaltar insectos, filtros para daltonismo, volumen y vibración. El juego se pausa solo cuando la aplicación se minimiza.")),
        sec(t("Tempo de tela", "Screen time", "Tiempo de pantalla"),
            t("As fases são curtas e podem ser interrompidas a qualquer momento sem perder o que já foi conquistado. Combine pausas com a criança e use o Family Link se quiser limitar o tempo de uso.",
              "Levels are short and can be stopped at any time without losing what has been earned. Agree on breaks with your child and use Family Link if you want to limit screen time.",
              "Los niveles son cortos y se pueden interrumpir en cualquier momento sin perder lo conseguido. Acuerda pausas con el niño y usa Family Link si quieres limitar el tiempo de uso.")),
    ],
}

DOCS = [TERMS, PRIVACY, RIGHTS, PARENTS]

UI = {
    "updated": t("Última atualização: %s · versão %s", "Last updated: %s · version %s", "Última actualización: %s · versión %s"),
    "by": t("GuardiPatas é desenvolvido por RetroNexa", "GuardiPatas is developed by RetroNexa", "GuardiPatas es desarrollado por RetroNexa"),
}


def build_json():
    return {
        "version": VERSION, "updated": UPDATED, "developer": DEVELOPER, "site": SITE, "email": EMAIL,
        "pages": PAGES, "date": DATE, "ui": UI, "docs": DOCS,
    }


LANG_NAMES = {"pt": "Português", "en": "English", "es": "Español"}


def md_doc(doc):
    out = ["# %s — %s / %s / %s" % (APP, doc["title"]["pt"], doc["title"]["en"], doc["title"]["es"]), "",
           "*Gerado por `tools/make_legal.py` (não edite à mão). Versão %s · %s*" % (VERSION, UPDATED), ""]
    for lang in LANGS:
        out += ["## " + LANG_NAMES[lang], "", "**%s**" % doc["summary"][lang], ""]
        for s in doc["sections"]:
            out += ["### " + s["h"][lang], ""]
            for p in s["p"]:
                out += [p[lang], ""]
        out += ["*" + UI["updated"][lang] % (DATE[lang], VERSION) + " — " + UI["by"][lang] + " · " + SITE + " · " + EMAIL + "*", ""]
    return "\n".join(out)


def html_doc(doc):
    e = html.escape
    parts = []
    for lang in LANGS:
        body = ["<h2>%s</h2>" % e(doc["title"][lang]), "<p class=\"sum\">%s</p>" % e(doc["summary"][lang])]
        for s in doc["sections"]:
            body.append("<h3>%s</h3>" % e(s["h"][lang]))
            body += ["<p>%s</p>" % e(p[lang]) for p in s["p"]]
        body.append("<p class=\"meta\">%s<br>%s · <a href=\"https://%s\">%s</a> · <a href=\"mailto:%s\">%s</a></p>"
                    % (e(UI["updated"][lang] % (DATE[lang], VERSION)), e(UI["by"][lang]), SITE, SITE, EMAIL, EMAIL))
        parts.append("<section lang=\"%s\" id=\"%s\">%s</section>" % ("pt-BR" if lang == "pt" else lang, lang, "\n".join(body)))
    nav = " · ".join("<a href=\"#%s\">%s</a>" % (l, LANG_NAMES[l]) for l in LANGS)
    return """<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{app} — {title}</title>
<style>
:root{{--bg:#f6f0e8;--card:#fffdf9;--ink:#4f4a5c;--muted:#7a7486;--accent:#5f9c8b}}
@media (prefers-color-scheme: dark){{:root{{--bg:#1f1d24;--card:#29262f;--ink:#ece7f2;--muted:#b3acbd;--accent:#8fcdb9}}}}
body{{margin:0;background:var(--bg);color:var(--ink);font:17px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}}
main{{max-width:760px;margin:0 auto;padding:24px 16px 48px}}
section{{background:var(--card);border-radius:20px;padding:20px 22px;margin:18px 0;box-shadow:0 1px 3px #0001}}
h1{{font-size:28px;margin:8px 0}} h2{{margin-top:4px}} h3{{font-size:18px;margin:22px 0 4px}}
.sum{{font-weight:600}} .meta{{color:var(--muted);font-size:14px;margin-top:24px}} a{{color:var(--accent)}} nav{{color:var(--muted)}}
</style></head>
<body><main><h1>{app}</h1><nav>{nav}</nav>
{parts}
</main></body></html>
""".format(app=APP, title=e(doc["title"]["pt"]), nav=nav, parts="\n".join(parts))


def write(path, text):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def main():
    write("data/legal.json", json.dumps(build_json(), ensure_ascii=False, indent=1) + "\n")
    write("docs/termos.md", md_doc(TERMS))
    write("docs/privacidade.md", md_doc(PRIVACY) + "\n" + "\n".join(md_doc(d).split("\n", 4)[4] for d in (RIGHTS, PARENTS)))
    write("docs/site/termos.html", html_doc(TERMS))
    write("docs/site/privacidade.html", html_doc(PRIVACY))
    write("docs/site/direitos.html", html_doc(RIGHTS))
    write("docs/site/responsaveis.html", html_doc(PARENTS))
    print("legal: versão %s, %d documentos" % (VERSION, len(DOCS)))


if __name__ == "__main__":
    main()
