#Использовать gitrunner
#использовать logos

Перем Лог;
Перем ШаблонОписаниеРелиза;

Процедура Запустить(Контекст) Экспорт
	
	Если Не Контекст.ОпубликоватьВыпуск Тогда
		Возврат;
	КонецЕсли;

	ОписаниеРелиза = СформированияТелоРелиза(Контекст);

	Репозиторий = Контекст.Настройка.НастройкаВыпускаГитхаба.Репозиторий;

	КлиентГитхаб = Новый КлиентГитхабAPI();
	КлиентГитхаб.УстановитьРепозиторий(Репозиторий.Владелец, Репозиторий.Имя);
	КлиентГитхаб.УстановитьТокенАвторизации(Контекст.Токен);

	Лог.Отладка("Создаю релиз <%1>", Контекст.Версия);
	ИдентификаторРелиза = СоздатьРелиз(КлиентГитхаб, Контекст, ОписаниеРелиза);
	Лог.Отладка("Идентификатор релиза <%1> для версии <%2>", ИдентификаторРелиза, Контекст.Версия);
	
	Для каждого Артифакт Из Контекст.Артифакты Цикл
		
		ЗагрузитьАртифакт(КлиентГитхаб, ИдентификаторРелиза, Артифакт);

	КонецЦикла;

КонецПроцедуры

Функция СоздатьРелиз(КлиентГитхаб, Контекст, ОписаниеРелиза)
	
	Версия = Контекст.Версия;

	Гитхаб = Контекст.Настройка.НастройкаВыпускаГитхаба;

	ИмяРелиза = Гитхаб.ШаблонИмени;

	ИдентификаторРелиза = КлиентГитхаб.ПолучитьРелизПоТегу(Версия);

	Если ИдентификаторРелиза = Неопределено Тогда
		
		КлиентГитхаб.СоздатьРелиз(Версия, ОписаниеРелиза, ИмяРелиза , Гитхаб.Черновик, Гитхаб.Предварительный);
		ИдентификаторРелиза = КлиентГитхаб.ПолучитьРелизПоТегу(Версия);

	Иначе

		КлиентГитхаб.ИзменитьРелиз(ИдентификаторРелиза, Версия, ОписаниеРелиза, ИмяРелиза , Гитхаб.Черновик, Гитхаб.Предварительный);

	КонецЕсли;

	Возврат ИдентификаторРелиза;

КонецФункции

Функция СформированияТелоРелиза(Контекст)
	
	ИтоговоеОписание = СтрЗаменить(ШаблонОписаниеРелиза, "{{ .ОписаниеВыпуска }}", Контекст.ОписаниеВыпуска);

	// TODO: доделать вывод докер образов в описание
	ИтоговоеОписание = СтрЗаменить(ИтоговоеОписание, "{{ .ОбразыДокер }}", "");

	Возврат ИтоговоеОписание;

КонецФункции

Процедура ЗагрузитьАртифакт(КлиентГитхаб, ИдентификаторРелиза, Артифакт)
	
	КлиентГитхаб.ЗагрузитьФайлРелиза(ИдентификаторРелиза, Артифакт.ПутьКФайлу, Артифакт.ИмяФайла);	

КонецПроцедуры

Процедура УстановитьНастройкиПоУмолчанию(Контекст) Экспорт
	
	Если НЕ ПустаяСтрока(Контекст.Настройка.НастройкаВыпускаГитхаба.ШаблонИмени) Тогда
		Контекст.Настройка.НастройкаВыпускаГитхаба.ШаблонИмени = "{{ .Тег }}";
	КонецЕсли;

	Репозиторий = Контекст.Настройка.НастройкаВыпускаГитхаба.Репозиторий;

	Если НЕ ПустаяСтрока(Репозиторий.Имя) Тогда
		Лог.Отладка("Имя <%1> и владелец <%2> репозитория уже заданы", Репозиторий.Имя, Репозиторий.Владелец);
		Возврат;
	КонецЕсли;

	НовыйРепозиторий = ПолучитьУдаленныйРепозиторий(Контекст);

	ЗаполнитьЗначенияСвойств(Репозиторий, НовыйРепозиторий);

КонецПроцедуры

Функция ПолучитьУдаленныйРепозиторий(Контекст)
	
	Репозиторий = Новый Структура("Имя, Владелец", "", "");

	ГитРепозиторий = Новый ГитРепозиторий();
	ГитРепозиторий.УстановитьТихийРежимРаботы();
	
	ГитРепозиторий.УстановитьРабочийКаталог(Контекст.РабочийКаталог);
	Лог.Отладка("Установлен рабочий каталог гит <%1>", Контекст.РабочийКаталог);
	Если НЕ ГитРепозиторий.ЭтоРепозиторий() Тогда
		Возврат Репозиторий;
	КонецЕсли;

	ПараметрыЗапуска = СтрРазделить("config --get remote.origin.url", " ");
	ГитРепозиторий.ВыполнитьКоманду(ПараметрыЗапуска);

	ИмяУдаленногоРепо = ГитРепозиторий.ПолучитьВыводКоманды();

	Лог.Отладка("Получено имя удаленного репозитория <%1>", ИмяУдаленногоРепо);

	МассивУдаленияСтрок = СтрРазделить(	"git@github.com: .git https://github.com/ \n", " ");

	Для каждого СтрокаЗамены Из МассивУдаленияСтрок Цикл
		ИмяУдаленногоРепо = СтрЗаменить(ИмяУдаленногоРепо, СтрокаЗамены, "");
	КонецЦикла;

	МассивИмен = СтрРазделить(ИмяУдаленногоРепо, "/");

	Если МассивИмен.Количество() = 2 Тогда
		
		Репозиторий.Имя = МассивИмен[0];
		Репозиторий.Владелец = МассивИмен[1];
		
	КонецЕсли;

	Возврат Репозиторий

КонецФункции

Процедура ОписаниеПараметров(Знач КонструкторПараметров) Экспорт
	
	Репозиторий = КонструкторПараметров.НовыеПараметры()
				.ПолеСтрока("Имя name")
				.ПолеСтрока("Владелец owner")
				;
	
	КонструкторПараметров.ПолеОбъект("Репозиторий repo", Репозиторий)
				.ПолеБулево("Черновик draft", Ложь)
				.ПолеБулево("Предварительный prerelease", Ложь)
				.ПолеСтрока("ШаблонИмени name_template", "{{ .Тег }}")
				;

КонецПроцедуры

Лог = Логирование.ПолучитьЛог("oscript.lib.orca.pipe.github");
Лог.УстановитьУровень(УровниЛога.Отладка);

ШаблонОписаниеРелиза = "{{ .ОписаниеВыпуска }}
|{{ .ОбразыДокер }}
|---
|Создано автоматически с помощью [ORCA](https://github.com/khorevaa/orca)
|";