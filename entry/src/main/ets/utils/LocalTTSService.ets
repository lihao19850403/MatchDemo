import { textToSpeech } from '@kit.CoreSpeechKit';

export class LocalTTSService {

  private static instance: LocalTTSService;

  private ttsEngine: textToSpeech.TextToSpeechEngine | undefined = undefined;

  /** 稍后再读。 */
  private latelyRead: string = '';

  private constructor() {
    if (canIUse("SystemCapability.AI.TextToSpeech")) {
      try {
        textToSpeech.createEngine({
          language: 'zh-CN',
          person: 0,
          online: 1
        }, (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
          if (!err) {
            this.ttsEngine = textToSpeechEngine;
          }
          if (this.ttsEngine !== undefined && this.latelyRead.length > 0) {
            this.speak(this.latelyRead);
            this.latelyRead = '';
          }
        });
      } catch (error) {
      }
    }
  }

  public static getInstance() {
    if (LocalTTSService.instance === undefined) {
      LocalTTSService.instance = new LocalTTSService();
    }
    return LocalTTSService.instance;
  }

  // 合成并播放文本
  public speak(text: string) {
    if (canIUse("SystemCapability.AI.TextToSpeech")) {
      if (this.ttsEngine === undefined) {
        this.latelyRead = text;
      } else {
        try {
          this.ttsEngine.speak(text, {
            requestId: Date.now().toString()
          });
        } catch (error) {
        }
      }
    }
  }

  public stop() {
    if (canIUse("SystemCapability.AI.TextToSpeech")) {
      this.ttsEngine?.stop();
    }
  }
}