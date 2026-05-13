import { LHAppSettingsTextSizePlanModel } from "../models/common/LHAppSettingsTextSizePlanModel";
import { ScreenObserver, ScreenStatusInfo } from "../utils/common/uiobserver/ScreenObserver";

@Component
export struct ClassroomArticle {

  /** 应用文字字号方案。 */
  @Prop appTextSizePlan: LHAppSettingsTextSizePlanModel;

  /** 当前屏幕状态信息。 */
  private screenStatus: ScreenStatusInfo | undefined = undefined;

  /** 文章内容。 */
  articleContent: string = '';

  aboutToAppear(): void {
    ScreenObserver.subscribe(this.getUIContext(), (screenStatus: ScreenStatusInfo) => {
      this.screenStatus = screenStatus;
    });
  }

  aboutToDisappear(): void {
    ScreenObserver.unsubscribe(this.getUIContext());
  }

  build() {
    Scroll() {
      Column() {
        Text(this.articleContent)
          .fontSize(this.appTextSizePlan.unifiedDialogContentTextSize)
        Blank().height(50)
      }
    }
    .height(200)
    .scrollBar(BarState.Off)
    .flexShrink(1)
    .borderRadius(4)
    .borderWidth(2)
    .borderColor($r('app.color.main_selected_color'))
    .backgroundColor(Color.White)
  }
}