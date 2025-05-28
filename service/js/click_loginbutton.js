function clickUniversityLoginButton(){
    // 特定の属性をもとにボタンを取得
    const button = document.querySelector('a[href*="auth/saml2/login.php"]');
    button?.click(); //クリック
}

function clickUserSelectionTile (){
    const buttons = document.querySelectorAll('div.table[role="button"]');
    if (buttons.length > 0) {
        const firstButton = buttons[0];
        // ボタンをクリック
        firstButton.click(); 

        // TextBoxが表示されるのを待つ
        waitForTextboxToAppear();
    }
};

function waitForTextboxToAppear() {
    // MutationObserverを使って、TextBoxがDOMに追加されるのを監視
    const observer = new MutationObserver((mutationsList, observer) => {
        // 新しいノードが追加されたか、表示されたかをチェック
        for (const mutation of mutationsList) {
            if (mutation.type === 'childList') {
                const textbox = document.querySelector('input[name="passwd"]'); // TextBoxのセレクタ
                if (textbox && textbox.offsetHeight > 0) {
                    // TextBoxが表示されたら、フォーカスを合わせる
                    textbox.focus();
                    observer.disconnect(); // 監視を停止
                    return;
                }
            }
        }
    });

    // DOMの変化を監視
    observer.observe(document.body, {
        childList: true, // 子要素の追加・削除を監視
        subtree: true     // サブツリー内も監視
    });
}

function focusTextbox(){
    const passwordField = document.querySelector('input[name="passwd"]');
    if(passwordField != null){
        // name="passwd" を使って特定し、フォーカスを合わせる
        passwordField.focus();
    }
}


window.clickUniversityLoginButton = clickUniversityLoginButton;
window.clickUserSelectionTile = clickUserSelectionTile;
window.focusTextbox = focusTextbox;