
import Foundation

public final class VMSPermission: Codable {
    
    public let id: Int?
    public let details: String?
    public let name: String?
    public let type: PermissionType
    public let typeString: String?
    
    public enum PermissionType: String, Codable {
        
        case LayoutsStore = "layouts-store"                         // Создание новых раскладок
        case LayoutsDestroy = "layouts-destroy"                     // Удаление существующих раскладок
        case LayoutsRename = "layouts-rename"                       // Переименование существующих раскладок
        case LayoutsCamerasAttach = "layouts-cameras-attach"        // Добавление камер в существующие раскладки
        case LayoutsCamerasDetach = "layouts-cameras-detach"        // Удаление камер из существующих раскладкок
        case GroupsIndex = "groups-index"                           // Просмотр групп камер (группы камер)
        case GroupsStore = "groups-store"                           // Создание новой папки (группы камер)
        case GroupsDestroy = "groups-destroy"                       // Удаление существующих папок (групп камер)
        case GroupsRename = "groups-rename"                         // Переименование существующих папок (групп камер)
        case GroupsCamerasAttach = "groups-cameras-attach"          // Добавление камер в существующие папки (группы камер)
        case GroupsCamerasDetach = "groups-cameras-detach"          // Удаление камер из существующих папок (групп камер)
        case ArhivesShow = "archives-show"                          // Просмотр архива камер
        case ArhivesDownload = "archives-download"                  // Сохранение архива камер
        case ArhivesPreviewDownload = "archives-preview-download"   // Сохранение скриншота камеры
        case Ptz = "ptz"                                            // Управление направлением и увеличением
        case CameraEventsStore = "camera-events-store"              // Создание пользовательских событий в архиве камеры
        case CameraEventsIndex = "camera-events-index"              // Просмотр событий камеры
        case LoginsStore = "logins-store"                           // Добавление логина
        case UsersIndex = "users-index"                             // Просмотр списка всех пользователей
        case UsersStore = "users-store"                             // Создание нового пользователя
        case UsersShow = "users-show"                               // Просмотр существующих пользователей
        case UsersUpdate = "users-update"                           // Обновление существующих пользователей
        case UsersDestroy = "users-destroy"                         // Удаление существующих пользователей
        case UsersChangePassword = "users-change-password"          // Изменение пароля для существующих пользователей
        case MarksIndex = "marks-index"                             // Просмотр меток
        case MarksStore = "marks-store"                             // Создание меток
        case MarksDestroy = "marks-destroy"                         // Удаление меток
        case MarksUpdate = "marks-update"                           // Редактирование меток
        case IntercomIndex = "intercom-index"                       // Доступ к домофонам(позже добавить различные пермишены для                                                            домофонов)
        case Analytic = "analytic"                                  // Просмотр аналитики
        
        /// Deprecated
        /// New name is "`analytic`
        /// Remove support in 24.09.00
        case AnalyticCasesIndex = "analytic-cases-index"            // Просмотр аналитики
        
        case Bridge = "bridges"                                     // Доступ к бриджам
        
        /// Deprecated
        /// From 24.03.00
        case IntercomFace = "intercom-face"                         // Распознвание лиц по домофону
        
        case Unknown = "unknown"                                    // Все другие, ненужные на мобильной платформе
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case details = "description"
        case name = "display_name"
        case type = "name"
    }
    
    public init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: CodingKeys.self)
        id = try? container.decodeIfPresent (Int.self, forKey: .id)
        details = try? container.decodeIfPresent (String.self, forKey: .details)
        name = try? container.decodeIfPresent (String.self, forKey: .name)
        typeString = try? container.decode (String.self, forKey: .type)
        type = PermissionType(rawValue: typeString ?? "unknown") ?? .Unknown
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(id, forKey: .id)
        try container.encode(details, forKey: .details)
        try container.encode(typeString, forKey: .type)
    }
}
