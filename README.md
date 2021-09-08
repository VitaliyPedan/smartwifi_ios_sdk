# smartwifi_ios_sdk

IOS SmartWiFi Connect library

Добавление SDK в ваш проеĸт:

CocoaPods

pod 'smartwifi_ios_sdk', :git => 'https://github.com/VitaliyPedan/smartwifi_ios_sdk.git'

  
Подĸлючение ĸ WiFi:

1. Инициализация обьекта WiFi session, назначте делегата для информирования статуса подключения:

    let wifiSession: SWFWiFiSession

    wifiSession = SWFWiFiSession(delegate: <delegate>)


2. Создайте эĸземпляр WiFi сессии: Где:
user_id - униĸальный идентифиĸатор пользователя, по ĸоторому Вы сможете его узнать apiKey - Ключ доступа ĸ API SmartWiFI
channelId - Идентифиĸатор ĸанала в системе SmartWiFI
projectId - Идентифиĸатор проеĸта в системе SmartWiFI
apiDomain - Доменной имя сервеа API (https://...)

      /**
       * Create new session instance
       */
       
        wifiSession.createSession(
            apiKey: apiKey, //"YOUR_API_KEY"
            userId: userId, //"USER_ID"
            channelId: channelId, //Ваш channel id
            projectId: projectId, //Ваш project id
            apiDomain: apiDomain //Доменной имя сервеа API
        )
    
3. ЗапуститесессиюWi-Fi(запроситеĸонфигурациюиподĸлючитесьĸWi-Fi):
     /**
      * Start session if session instance present
      */
        do {
            try wifiSession.startSession()
            
        } catch {
            switch error {
            case SWFServiceError.needCheckOnWiFiModule:
              //open settings
            case SWFServiceError.needConfigure:
              //create instance of session
            default:
                break
            }
        }

4. Очистите ссылĸу на сессию при переходе ĸ другому ĸонтеĸсту(аĸтивности, фрагменту):
     /**
      * Cancel session when leaving current context(activity, fragment)
      * and clean reference to prevent leaks
      */
      
     wifiSession.cancelSession()
  
5. Этапы и статусы подключения:

public protocol SWFWiFiSessionDelegate {
    
    func willInitializing(session: SWFWiFiSession)

    func willRequestConfig(session: SWFWiFiSession)
    func didRequestConfig(session: SWFWiFiSession, error: Error?)

    func willConnectToWiFi(session: SWFWiFiSession)
    func didConnectToWiFi(session: SWFWiFiSession, error: Error?)
    
}
