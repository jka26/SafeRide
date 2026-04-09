import {
    ArgumentsHost,
    Catch,
    ExceptionFilter,
    HttpException,
    HttpStatus,
    Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

export interface ApiErrorResponse {
    statusCode: number;
    error: string;
    message: string | string[];
    timestamp: string;
    path: string;
}

/**
 * Catches all exceptions and formats them into a consistent API error envelope:
 * {
 *   statusCode: number,
 *   error: string,        // e.g. "Not Found", "Forbidden"
 *   message: string | string[],
 *   timestamp: string,
 *   path: string,
 * }
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
    private readonly logger = new Logger(AllExceptionsFilter.name);

    catch(exception: unknown, host: ArgumentsHost) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse<Response>();
        const request = ctx.getRequest<Request>();

        let statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
        let message: string | string[] = 'Internal server error';
        let error = 'Internal Server Error';

        if (exception instanceof HttpException) {
            statusCode = exception.getStatus();
            const res = exception.getResponse();
            if (typeof res === 'string') {
                message = res;
            } else if (typeof res === 'object' && res !== null) {
                const resObj = res as Record<string, unknown>;
                message = (resObj.message as string | string[]) ?? message;
                error = (resObj.error as string) ?? HttpStatus[statusCode] ?? error;
            }
        } else {
            this.logger.error('Unexpected exception', exception as Error);
        }

        const body: ApiErrorResponse = {
            statusCode,
            error,
            message,
            timestamp: new Date().toISOString(),
            path: request.url,
        };

        response.status(statusCode).json(body);
    }
}
