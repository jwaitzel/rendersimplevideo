//
//  ToSAndPPView.swift
//  RenderSampleVideo
//
//  Created by javi www on 6/7/23.
//

import SwiftUI

struct ToSAndPPView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(tosAllText)
                .padding(.top, 44)
            
            Text(ppText)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

struct ToSAndPPView_Previews: PreviewProvider {
    static var previews: some View {
        ToSAndPPView()
    }
}

let tosAllText = """
Terms of Service for Simple Video Mockup
Last updated: June 2024
Please read these Terms of Service ("Terms") carefully before using the Simple Video Mockup mobile application (the "Service") operated by JRWAppDev ("us", "we", or "our").

Acceptance of Terms

By using the Service, you agree to these Terms. If you disagree with any part of the Terms, you must not use the Service.

Description of Service

Simple Video Mockup is a mobile application designed to create GIFs for real estate advertisements. The app operates locally on your device and does not collect or transmit any user data.

Use of Service

You agree to use the Service only for lawful purposes and in accordance with these Terms. You are responsible for ensuring that your use of the Service complies with applicable laws and regulations.

Intellectual Property

The Service and its original content, features, and functionality are and will remain the exclusive property of JRWAppDev and its licensors.

Disclaimer of Warranties

The Service is provided "as is" and "as available" without any warranties of any kind, either express or implied.

Limitation of Liability

In no event shall JRWAppDev be liable for any indirect, incidental, special, consequential or punitive damages resulting from your use of the Service.

Changes to Terms

We reserve the right to modify or replace these Terms at any time. By continuing to use the Service after those revisions become effective, you agree to be bound by the revised Terms.

Contact Us

If you have any questions about these Terms, please contact us at jrwappdev@gmail.com.
By using Simple Video Mockup, you acknowledge that you have read and understood these Terms.

"""


let ppText = """
Privacy Policy for Simple Video Mockup
Last updated: June 2024
JRWAppDev ("we", "us", or "our") operates the Simple Video Mockup mobile application (the "Service"). This policy informs you of our approach to privacy and data handling.

No Data Collection

We do not collect, store, or process any personal data or usage information. The Simple Video Mockup app functions solely to create GIFs and does not require or gather any user data to operate.

App Functionality

The app's sole function is to create GIFs for real estate advertisements. All operations are performed locally on your device, and no data is transmitted to our servers or any third parties.

Third-Party Services

Our app does not integrate with any third-party services that might collect data.

Changes To This Privacy Policy

We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.

Contact Us

If you have any questions about this Privacy Policy, please contact us at [Your Contact Information].
By using the Service, you acknowledge that you have read and understood this policy.
"""
