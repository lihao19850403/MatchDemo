import { LHAppSettingsTextSizePlanModel } from "../models/common/LHAppSettingsTextSizePlanModel";
import { KVUtils } from "../utils/common/KVUtils";
import { ScreenObserver, ScreenStatusInfo } from "../utils/common/uiobserver/ScreenObserver";
import { taskpool, util } from "@kit.ArkTS";
import { GlobalContext } from "../utils/common/GlobalContext";
import preferences from "@ohos.data.preferences";
import { getScreenUIType, ScreenUIType } from "../utils/common/ScreenUIAdapter";
import { GlobalConfig, GLOBAL_CONFIG_KEY_WINDOW } from "../utils/common/GlobalConfig";
import window from "@ohos.window";
import { WordItem } from "../models/WordItem";
import { WordListDataSource } from "../models/WordListDataSource";
import { LocalTTSService } from "../utils/LocalTTSService";

/** 单词本名称列表。 */
const DICTIONARY_NAMES: string[] = ['CET4', 'CET6', '初中', '高中', '考研', '托福', 'SAT'];

/**
 * 首页 - 单词本 - 内容。
 * @author li.hao85
 */
@Component
export struct HomeTabNoteContent {

  /** 应用文字字号方案。 */
  @Prop appTextSizePlan: LHAppSettingsTextSizePlanModel;

  /** 当前屏幕状态信息。 */
  private screenStatus: ScreenStatusInfo | undefined = undefined;

  /** 列数规定。 */
  @State columnsTemplate: string = '';

  /** 单词本是否准备就绪。 */
  @State private wordBooksReady: boolean = false;

  /** 默认使用的词典。 */
  @State private useDictionary: string = DICTIONARY_NAMES[0];

  /** 当前单词列表。 */
  @State private curWordsList: WordListDataSource = new WordListDataSource();

  /** 未找到待查单词。 */
  @State private wordListEmpty: boolean = false;

  /** 当前待查找的单词。 */
  private curWord: string = '';

  aboutToAppear(): void {
    ScreenObserver.subscribe(this.getUIContext(), (screenStatus: ScreenStatusInfo) => {
      this.screenStatus = screenStatus;
      this.calcColumnTemplate();
    });
    this.calcColumnTemplate();
    // 准备单词本。
    this.prepareWordBooks();
    // 初始查询一次单词本。
    if (this.wordBooksReady === true) {
      this.queryWord();
    }
  }

  aboutToDisappear(): void {
    ScreenObserver.unsubscribe(this.getUIContext());
  }

  build() {
    Column() {
      if (this.wordBooksReady) {
        Row({ space: 8 }) {
          TextInput({ placeholder: $r('app.string.home_tab_note_query_word') })
            .fontSize(this.appTextSizePlan.unifiedDialogContentTextSize)
            .layoutWeight(1)
            .onChange((newValue: string) => {
              if (this.curWord !== newValue) {
                this.curWord = newValue;
                this.queryWord();
              }
            })
          Button(this.useDictionary)
            .bindMenu(DICTIONARY_NAMES.map((dictionaryName: string) => {
              return {
                value: dictionaryName,
                action: () => {
                  if (this.useDictionary !== dictionaryName) {
                    this.useDictionary = dictionaryName;
                    this.queryWord();
                  }
                }
              } as MenuElement;
            }))
        }
        .width('100%')
        .padding(8)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)
        Column() {
          if (this.wordListEmpty) {
            Text($r('app.string.home_tab_note_empty_tip'))
              .fontSize(this.appTextSizePlan.unifiedDialogTitleTextSize)
          } else {
            WaterFlow() {
              LazyForEach(this.curWordsList, (wordItem: WordItem, index: number) => {
                FlowItem() {
                  this.WordCard(wordItem)
                }
              }, (wordItem: WordItem, index: number) => JSON.stringify(wordItem) + index)
            }
            .columnsTemplate(this.columnsTemplate)
            .columnsGap(4)
            .rowsGap(4)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .edgeEffect(EdgeEffect.None)
            .scrollBar(BarState.Off)
            .cachedCount(4)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      } else {
        Text($r('app.string.home_tab_note_prepare_word_book'))
          .fontSize(this.appTextSizePlan.unifiedDialogTitleTextSize)
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private WordCard(wordItem: WordItem) {
    Button() {
      Column({ space: 8 }) {
        Row() {
          Text(wordItem.word)
            .fontSize(this.appTextSizePlan.unifiedDialogTitleTextSize)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          if (canIUse("SystemCapability.AI.TextToSpeech")) {
            Image($r('app.media.ic_speak'))
              .objectFit(ImageFit.Contain)
              .width(25)
              .height(25)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        Text(wordItem.meaning)
          .fontSize(this.appTextSizePlan.unifiedDialogContentTextSize)
          .fontColor(Color.Gray)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .padding(8)
    }
    .borderRadius(4)
    .backgroundColor(Color.White)
    .onClick(() => LocalTTSService.getInstance().speak(wordItem.word))
  }

  /**
   * 计算列数。
   */
  private calcColumnTemplate() {
    try {
      let screenUIType = this.screenStatus?.screenUIType ?? getScreenUIType();
      let windowStatusType = this.screenStatus?.windowStatusType ?? (GlobalConfig.get(GLOBAL_CONFIG_KEY_WINDOW) as window.Window).getWindowStatus();
      let windowWidthBreakpoint = this.screenStatus?.windowWidthBreakpoint ?? this.getUIContext().getWindowWidthBreakpoint();
      // 计算列数。
      this.columnsTemplate =
        windowStatusType === window.WindowStatusType.FLOATING || windowStatusType === window.WindowStatusType.SPLIT_SCREEN ? (
          screenUIType === ScreenUIType.PAD && windowWidthBreakpoint === WidthBreakpoint.WIDTH_MD ? '1fr 1fr' :
          screenUIType === ScreenUIType.PAD && windowWidthBreakpoint >= WidthBreakpoint.WIDTH_LG ? '1fr 1fr 1fr' :
          '1fr'
        ) :
        (
          screenUIType === ScreenUIType.FOLD_OPENED ? '1fr 1fr' :
          screenUIType === ScreenUIType.PAD ? '1fr 1fr 1fr' :
          '1fr'
        );
    } catch (error) {
    }
  }

  /** 准备所有单词本。 */
  private prepareWordBooks() {
    let finishedCount: number = 0;
    DICTIONARY_NAMES.forEach((dictionaryName: string) => {
      if (KVUtils.hasKV(dictionaryName, '__finish__') && KVUtils.queryKV(dictionaryName, '__finish__') === true) {
        finishedCount++;
      }
    });
    if (finishedCount === DICTIONARY_NAMES.length) {
      this.wordBooksReady = true;
    } else {
      let taskGroup: taskpool.TaskGroup = new taskpool.TaskGroup();
      DICTIONARY_NAMES.forEach((dictionaryName: string) => {
        let context: Context | undefined = GlobalContext.getContext();
        if (context) {
          let task: taskpool.Task = new taskpool.Task(initOneWordBook, context, dictionaryName);
          try {
            taskGroup.addTask(task);
          } catch (error) {
          }
        }
      });
      taskpool.execute(taskGroup)
        .then(() => {
          this.wordBooksReady = true
          this.queryWord();
        })
        .catch((error: BusinessError) => {})
    }
  }

  /** 查找单词信息并展示。 */
  private queryWord() {
    this.curWordsList.cleanAll();
    if (this.curWord === undefined || this.curWord.length === 0) {
      let allWords = KVUtils.queryAllKVs(this.useDictionary);
      Object.entries(allWords).forEach((pair: [string, string]) => {
        if (pair[0] !== undefined && pair[0].length > 0 && pair[0] !== '__finish__') {
          let wordItem: WordItem = { word: pair[0], meaning: pair[1] };
          this.curWordsList.pushData(wordItem);
        }
      });
    } else if (this.curWord.length >= 2 && KVUtils.hasKV(this.useDictionary, this.curWord)) {
      let meaning: string = KVUtils.queryKV(this.useDictionary, this.curWord) as string;
      let wordItem: WordItem = { word: this.curWord, meaning: meaning };
      this.curWordsList.pushData(wordItem);
    }
    this.wordListEmpty = this.curWordsList.totalCount() === 0;
  }
}

/**
 * 初始化一本单词本。
 * @param context 应用上下文。
 * @param dictionaryName 单词本名称。
 */
@Concurrent
async function initOneWordBook(context: Context, dictionaryName: string): Promise<boolean> {
  let fileName: string = 'dictionaries/' + dictionaryName + '.txt';
  try {
    let handler = preferences.getPreferencesSync(context, { name: dictionaryName });
    let rawFile = context.resourceManager.getRawFileContentSync(fileName);
    let textDecoder = util.TextDecoder.create('UTF-8', { ignoreBOM: true });
    let originalContent: string = textDecoder.decodeToString(rawFile, { stream: false });
    let infos: string[] = originalContent.split('\n');
    infos.forEach((info: string) => {
      let infoPair = info.split('\t');
      let word = infoPair[0].trim();
      let meaning = infoPair[1].trim();
      if (word !== undefined && word.length > 0 && meaning !== undefined && meaning.length > 0) {
        handler.putSync(word, meaning);
      }
    });
    handler.putSync('__finish__', true);
    handler.flushSync();
  } catch (error) {
    return false;
  }
  return true;
}